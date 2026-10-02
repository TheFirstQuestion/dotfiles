#!/usr/bin/env node

import { spawnSync } from 'child_process';

interface Comment {
  id: number;
  author: string;
  author_type: 'Human' | 'Bot' | 'Unknown';
  path: string;
  line?: number | null;
  body: string;
  created_at: string;
  replies: Reply[];
  // True for comments synthesized from a PR review body (the top-level comment
  // left when a reviewer submits a review, or an issue embedded inside one).
  // These have no reply endpoint of their own — see pr-comments-address Step 8.
  synthetic?: boolean;
  // Set when a synthetic comment was extracted from inside a review body
  // (e.g. a "previously missed" item in a bot's collapsed findings list).
  source_review_id?: number;
}

interface Reply {
  id: number;
  author: string;
  author_type: 'Human' | 'Bot' | 'Unknown';
  body: string;
  created_at: string;
}

interface GraphQLCommentNode {
  databaseId: number;
  author?: { login: string; __typename: string } | null;
  path: string;
  line?: number | null;
  originalLine?: number | null;
  body: string;
  createdAt: string;
}

interface GraphQLThreadNode {
  isResolved: boolean;
  comments: { nodes: GraphQLCommentNode[] };
}

interface GraphQLPage {
  data: {
    repository: {
      pullRequest: {
        reviewThreads: {
          pageInfo: { hasNextPage: boolean; endCursor?: string | null };
          nodes: GraphQLThreadNode[];
        };
      };
    };
  };
}

interface RawGeneralComment {
  id: number;
  author: string;
  author_type: 'Human' | 'Bot' | 'Unknown';
  path: string;
  line?: number | null;
  body: string;
  created_at: string;
}

interface RawReview {
  id: number;
  author: string;
  author_type: 'Human' | 'Bot' | 'Unknown';
  body: string;
  created_at: string;
}

function authorTypeFromTypename(typename: string | undefined): 'Human' | 'Bot' | 'Unknown' {
  if (typename === undefined) return 'Unknown';
  return typename === 'Bot' ? 'Bot' : 'Human';
}

function run(args: string[]): string {
  const result = spawnSync('gh', args, {
    encoding: 'utf8',
    maxBuffer: 50 * 1024 * 1024,
  });
  if (result.error != null) throw result.error;
  if (result.status !== 0)
    throw new Error(
      result.stderr?.trim() || `gh exited with ${String(result.status)}`,
    );
  return result.stdout.trim();
}

function repoSlug(): string {
  return run([
    'repo',
    'view',
    '--json',
    'nameWithOwner',
    '--jq',
    '.nameWithOwner',
  ]);
}

function parseRestPages<T>(raw: string): T[] {
  const trimmed = raw.trim();
  if (!trimmed || trimmed === '[]') return [];
  return trimmed.split(/\n(?=\[)/).flatMap((page) => JSON.parse(page) as T[]);
}

function parseGraphqlPages(raw: string): GraphQLPage[] {
  const trimmed = raw.trim();
  if (!trimmed) return [];
  return trimmed
    .split(/\n(?=\{)/)
    .map((page) => JSON.parse(page) as GraphQLPage);
}

// Uses GraphQL reviewThreads and filters to return only unresolved threads.
const reviewThreadsQuery = `
  query($owner: String!, $repo: String!, $pr: Int!, $endCursor: String) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 100, after: $endCursor) {
          pageInfo { hasNextPage endCursor }
          nodes {
            isResolved
            comments(first: 100) {
              nodes {
                databaseId
                author { login __typename }
                path
                line
                originalLine
                body
                createdAt
              }
            }
          }
        }
      }
    }
  }
`;

function fetchInlineUnresolved(pr: string, slug: string): Comment[] {
  const [owner, repo] = slug.split('/');

  const pagesRaw = run([
    'api',
    'graphql',
    '--paginate',
    '-f',
    `query=${reviewThreadsQuery}`,
    '-f',
    `owner=${owner}`,
    '-f',
    `repo=${repo}`,
    '-F',
    `pr=${pr}`,
  ]);

  const threads = parseGraphqlPages(pagesRaw).flatMap(
    (p) => p.data.repository.pullRequest.reviewThreads.nodes,
  );

  return threads
    .filter((t) => !t.isResolved && t.comments.nodes.length > 0)
    .map((t) => {
      const [root, ...replies] = t.comments.nodes;
      return {
        id: root.databaseId,
        author: root.author?.login ?? '(deleted)',
        author_type: authorTypeFromTypename(root.author?.__typename),
        path: root.path,
        line: root.line ?? root.originalLine,
        body: root.body,
        created_at: root.createdAt,
        replies: replies
          .sort(
            (a, b) =>
              new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime(),
          )
          .map((r) => ({
            id: r.databaseId,
            author: r.author?.login ?? '(deleted)',
            author_type: authorTypeFromTypename(r.author?.__typename),
            body: r.body,
            created_at: r.createdAt,
          })),
      };
    });
}

function fetchGeneral(pr: string, slug: string): Comment[] {
  const jq =
    '[.[] | {id:.id, author:(.user.login // "(deleted)"), author_type:(if .user == null then "Unknown" elif .user.type == "Bot" then "Bot" else "Human" end), path:"(general)", line:null, body:.body, created_at:.created_at}]';
  const raw = run([
    'api',
    `repos/${slug}/issues/${pr}/comments`,
    '--paginate',
    '--jq',
    jq,
  ]);
  return parseRestPages<RawGeneralComment>(raw).map((c) => ({
    ...c,
    replies: [],
  }));
}

function fetchReviews(pr: string, slug: string): RawReview[] {
  const jq =
    '[.[] | select(.body != null and .body != "") | {id:.id, author:(.user.login // "(deleted)"), author_type:(if .user == null then "Unknown" elif .user.type == "Bot" then "Bot" else "Human" end), body:.body, created_at:.submitted_at}]';
  const raw = run([
    'api',
    `repos/${slug}/pulls/${pr}/reviews`,
    '--paginate',
    '--jq',
    jq,
  ]);
  return parseRestPages<RawReview>(raw);
}

const ZERO_WIDTH_SPACE = /​/g;

function stripHtml(s: string): string {
  return s.replace(/<[^>]+>/g, '').replace(ZERO_WIDTH_SPACE, '').replace(/\s+/g, ' ').trim();
}

// Finds every <details>...</details> block in a review body (regardless of
// nesting) and returns only the leaf blocks — those with no further <details>
// nested inside them. Bots like the Copilot code-review reviewer wrap each
// individually embedded finding (e.g. a "previously missed" item) in its own
// nested <details>, while group headers ("Open (N)", "Resolved since last
// review (N)") wrap a flat bullet list with no further nesting.
function findLeafDetailsBlocks(body: string): { start: number; end: number }[] {
  const tagRe = /<details\b[^>]*>|<\/details>/gi;
  const stack: number[] = [];
  const blocks: { start: number; end: number }[] = [];
  let m: RegExpExecArray | null;
  while ((m = tagRe.exec(body)) !== null) {
    if (m[0].toLowerCase().startsWith('<details')) {
      stack.push(m.index);
    } else {
      const start = stack.pop();
      if (start !== undefined) blocks.push({ start, end: m.index + m[0].length });
    }
  }
  return blocks.filter(
    (b) => !blocks.some((o) => o !== b && o.start > b.start && o.end < b.end),
  );
}

// Pulls individually embedded findings out of a review body — text that
// describes a concrete, actionable issue but was never posted as its own
// inline review comment (so fetchInlineUnresolved can never see it). Plain
// link-list group headers ("Open (N)", "Resolved since last review (N)") are
// filtered out: they only reference discussion IDs that already exist as
// real comments elsewhere, so splitting them out here would just duplicate
// those entries.
// Known non-finding section headers used by review bots (Copilot, etc.) that
// happen to be leaf <details> blocks with real prose but describe the review
// as a whole rather than a single actionable issue.
const NON_FINDING_TITLE_RE =
  /^(open|resolved since last review|previously missed|what changed in this pr)\s*(\(\d+\))?$/i;

function extractEmbeddedFindings(review: RawReview): Comment[] {
  const findings: Comment[] = [];
  for (const block of findLeafDetailsBlocks(review.body)) {
    const chunk = review.body.slice(block.start, block.end);
    const summaryMatch = /<summary>([\s\S]*?)<\/summary>/i.exec(chunk);
    if (!summaryMatch) continue;
    const title = stripHtml(summaryMatch[1]);
    if (NON_FINDING_TITLE_RE.test(title)) continue;
    const rest = chunk
      .slice(summaryMatch.index + summaryMatch[0].length)
      .replace(/<\/details>\s*$/i, '');
    const locMatch = /`([^`:\n]+):(\d+)(?::\d+)?`/.exec(rest);
    const path = locMatch ? locMatch[1].replace(ZERO_WIDTH_SPACE, '') : '(general)';
    const line = locMatch ? parseInt(locMatch[2], 10) : null;
    const afterLoc = locMatch ? rest.slice(locMatch.index + locMatch[0].length) : rest;
    const bodyText = stripHtml(afterLoc).replace(/\[[^\]]*\]\([^)]*\)/g, '').trim();

    // No file:line and essentially no prose left after stripping tags/links —
    // this is a bare group header, not a real finding.
    if (!locMatch && bodyText.replace(/[-*•·\s]/g, '').length < 20) continue;

    findings.push({
      id: review.id * 1000 + findings.length,
      author: review.author,
      author_type: review.author_type,
      path,
      line,
      body: title && bodyText ? `${title}\n\n${bodyText}` : title || bodyText,
      created_at: review.created_at,
      replies: [],
      synthetic: true,
      source_review_id: review.id,
    });
  }
  return findings;
}

function fetchReviewFindings(pr: string, slug: string): Comment[] {
  const results: Comment[] = [];
  for (const review of fetchReviews(pr, slug)) {
    const embedded = extractEmbeddedFindings(review);
    if (embedded.length > 0) {
      results.push(...embedded);
      continue;
    }
    // No embedded findings parsed out — fall back to surfacing the whole
    // review body as a single top-level comment, so nothing is silently
    // dropped just because it doesn't match the known bot HTML shape.
    const cleaned = stripHtml(review.body);
    if (cleaned.length > 20) {
      results.push({
        id: review.id,
        author: review.author,
        author_type: review.author_type,
        path: '(general)',
        line: null,
        body: review.body,
        created_at: review.created_at,
        replies: [],
        synthetic: true,
      });
    }
  }
  return results;
}

function main(): void {
  const pr = process.argv[2]?.replace(/^#/, '');
  if (!pr?.trim()) {
    console.error('Usage: get_pr_comments.ts <pr-number>');
    process.exit(1);
  }

  const slug = repoSlug();
  const inline = fetchInlineUnresolved(pr, slug);
  const general = fetchGeneral(pr, slug);
  const reviewFindings = fetchReviewFindings(pr, slug);

  console.log(JSON.stringify([...inline, ...general, ...reviewFindings], undefined, 2));
}

try {
  main();
} catch (err) {
  console.error('[get_pr_comments]', err);
  process.exit(1);
}
