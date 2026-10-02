# Senior PR Learnings

Recurring gaps surfaced while reviewing PRs a senior dev wrote (not my own code).
Appended by `/senior-pr-questions` at the end of each session.
Read by `/quiz-me` and `/after-pr-questions` at startup to bias questions toward historical weak spots.

## Format

Each entry:
- **Date** — when the PR was reviewed
- **PR** — link or title (optional)
- **Repo** — repository the PR was from
- **Author** — the senior dev who wrote it (optional)
- **Category** — Architecture | Mechanics | Counterfactuals | Growth
- **Topic** — short label for the concept
- **What I missed** — the wrong or incomplete answer
- **Correct understanding** — the precise thing I needed to say, as reached by end of session
- **Principle** — the general engineering rule this question was testing

---

<!-- entries appended below -->
- **Date:** 2026-09-01 | **PR:** CURA-1406 (feat) Move improved patch for Connect Demo from UAT | **Repo:** dimer-cura-node | **Author:** 7Koston | **Category:** Mechanics | **Topic:** `??` (nullish coalescing) does not catch empty string
  - What I missed: Traced `singleHeader(req.headers['x-dh-flavor'])?.trim() ?? dhAppFlavorDimer` and said a whitespace-only header (trims to `""`) would be caught by `??` and default to `dhAppFlavorDimer` at that line.
  - Correct understanding: `??` only checks for `null`/`undefined` on its left-hand side, never falsy values like `""`, `0`, or `false`. `rawFlavor` stays `""`; the code only ends up at the correct default because a *second*, separate ternary (`isDhAppFlavor(rawFlavor) || ... ? rawFlavor : dhAppFlavorDimer`) catches the empty string later. Get the first line wrong and you'd wrongly conclude the function has one fewer layer of defense than it does.
  - Principle: Never reach for `??` as a generic "handle bad/empty input" operator — it is null/undefined-only. Falsy-but-defined values (`""`, `0`, `false`) sail through unchanged. This is the same family of mistake as `||` vs `??` confusion, just hitting the wrong operator's actual contract instead.

- **Date:** 2026-09-01 | **PR:** CURA-1406 (feat) Move improved patch for Connect Demo from UAT | **Repo:** dimer-cura-node | **Author:** 7Koston | **Category:** Architecture | **Topic:** Exact-pinning an actively co-developed internal package vs. caret-ranging a stable third-party one
  - What I missed: First guess was that exact-pinning `@dimer-health/ts-utils` (no caret, vs. every other dep's `^` range) meant "we always want the latest version" — backwards; exact-pin freezes the version and blocks automatic upgrades. Second guess was that the risk was "missing exports" at the resolved version — but the specifier itself (`1.12.0`) already guarantees the needed exports exist; caret vs. exact doesn't change the lower bound.
  - Correct understanding: The risk caret-ranging protects against for a mature third-party lib (predictable, well-tested patch releases) doesn't hold for an internal package under active development in lockstep with the very feature being shipped. A "patch" bump to `ts-utils` could ship an unreviewed change to brand-new, unproven exports (`dhReferralChannelNone`, `isOneOfDhAppFlavorConnectDemo`) this PR just started depending on. Exact-pinning freezes the dependency at the version this PR was actually developed and tested against, deferring any upgrade to a deliberate, separate bump.
  - Principle: Caret ranges assume the dependency's semver discipline is trustworthy for unattended patch upgrades. That assumption is much weaker for an in-house package being actively developed alongside your own feature than for a mature, stable third-party library — don't apply the same default (`^`) reflexively to both.

- **Date:** 2026-09-30 | **PR:** MOBI-671 Clear stale AI-chat snapshot cache after appointment booking and cancellation | **Repo:** dimer-cura-node | **Author:** 7Koston | **Category:** Mechanics | **Topic:** Allowlist-to-blocklist refactor inverts behavior for out-of-domain values; "eventually expires" assumed a TTL that doesn't exist
  - What I missed: Explained `pendingJobStates.has(state)` (old) vs `!isFinishedStatus(state)` (new) diverging on BullMQ's `'unknown'` state only mechanically ("it's not in the [pending] list, and it's not a finished status") without naming the underlying default-assumption flip. Then, asked whether the post-invalidation snapshot rebuild would still happen, said "it will eventually [rebuild] when it expires" — wrong, since the invalidation-path (`skipCooldown: true`) dedup key is built via `buildDeduplicationOptions(id, ttl, skipTtl=true)` → `{ id, keepLastIfActive: true }`, which carries no TTL at all.
  - Correct understanding: The OLD allowlist (`pendingJobStates`) treats anything outside its 5 named states — including BullMQ's `'unknown'` sentinel — as "not pending," so a stale dedup key gets removed by default. The NEW blocklist (`isFinishedStatus`) treats anything that isn't `completed`/`failed` — including `'unknown'` — as "still pending," so the key is kept and `SnapshotCreationQueue.addJob` collapses onto the existing (possibly stuck) job instead of enqueueing a fresh one. Because that key has `keepLastIfActive: true` and no `ttl`, it only clears when the job it points to actually reaches `completed`/`failed` — an `'unknown'`-state job gives no such guarantee, so the post-booking/cancellation snapshot rebuild this PR depends on can silently never happen, with no time-based recovery.
  - Principle: When a refactor swaps an allowlist for the complementary-looking blocklist over the same enum, check what happens for values outside the enum's known cases — the two forms are equivalent only inside the domain; outside it, they invert. Never assume "it'll expire eventually" without checking whether the resource was actually created with a TTL.

- **Date:** 2026-09-30 | **PR:** MOBI-671 Clear stale AI-chat snapshot cache after appointment booking and cancellation | **Repo:** dimer-cura-node | **Author:** 7Koston | **Category:** Architecture | **Topic:** Which step (cache clear vs. cache rebuild) is actually gated by flavor in the post-booking invalidation path
  - What I missed: Asked why guest bookings (`appointment-booking.e.routes.ts`) keep the undefaulted `dhFlavor` while five other routes add `?? dhAppFlavorDimer`, first said defaulting it "would have incorrectly cleared the dimer snapshot only" — wrong; `removeCachedSnapshotsForPatient` is never scoped by flavor, it unconditionally wipes every cached flavor for the patient.
  - Correct understanding: Only the *rebuild* step is flavor-gated — `appointment-booking.service.ts`'s `completeBooking` calls `removeCachedSnapshotsForPatient` unconditionally, then `if (flavor) { void this.snapshotCoordinator.refreshSnapshot(...) }`. Defaulting an unset flavor to `dimer` for a flavorless legacy-web guest booking would cause an unnecessary proactive rebuild of a flavor with no real association to that request — a wasted Athena/Medplum round trip, a wasted BullMQ job, and a wasted Redis write for a cache key that may never be read (the same "don't eagerly rebuild a never-cached flavor" principle from the 2026-09-21 quiz-learnings entry).
  - Principle: Before explaining why a design gates behavior on a value, trace which specific step in the code is actually conditioned on that value — don't assume the most dramatic-sounding step (deletion) is the gated one when a milder step (rebuild) is.
