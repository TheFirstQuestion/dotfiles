#!/usr/bin/env node

import { spawnSync } from 'child_process';

interface Comment {
  id: number;
  author: string;
  path: string;
  line?: number | null;
  body: string;
  created_at: string;
  replies: Reply[];
}

interface Reply {
  id: number;
  author: string;
  body: string;
  created_at: string;
}

interface GraphQLCommentNode {
  databaseId: number;
  author?: { login: string } | null;
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
  path: string;
  line?: number | null;
  body: string;
  created_at: string;
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
                author { login }
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
            body: r.body,
            created_at: r.createdAt,
          })),
      };
    });
}

function fetchGeneral(pr: string, slug: string): Comment[] {
  const jq =
    '[.[] | {id:.id, author:(.user.login // "(deleted)"), path:"(general)", line:null, body:.body, created_at:.created_at}]';
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

function main(): void {
  const pr = process.argv[2]?.replace(/^#/, '');
  if (!pr?.trim()) {
    console.error('Usage: get_pr_comments.ts <pr-number>');
    process.exit(1);
  }

  const slug = repoSlug();
  const inline = fetchInlineUnresolved(pr, slug);
  const general = fetchGeneral(pr, slug);

  console.log(JSON.stringify([...inline, ...general], undefined, 2));
}

try {
  main();
} catch (err) {
  console.error('[get_pr_comments]', err);
  process.exit(1);
}
