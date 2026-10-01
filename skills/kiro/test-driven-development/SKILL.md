---
name: test-driven-development
description: Use this once a test plan (from writing-test-plan) is approved and it's time to actually write code. Drives red-green-refactor from that test plan — writes test code that's traceably tied to each test-plan case, confirms it fails for the right reason before any implementation exists, then implements just enough to pass, placing each piece of logic in the right architectural layer (business/application vs infrastructure) based on how the current project is actually organized. Trigger for "let's implement this", "write the code for this plan", or any point where a test plan already exists and it's time to turn it into working code. Do NOT use this to decide what to build (that's writing-plans) or what to test (that's writing-test-plan) — this is strictly the build-it step.
license: MIT
metadata:
  author: "Dũng"
  version: "0.2.0"
  kit: groundwork
---

# Test-Driven Development

## What this is for

This is where the test plan and the plan finally become real code. Two things can quietly go wrong here that this skill exists to prevent: the test code drifts from what the test plan actually said (someone "interprets" a test case while writing it and ends up testing something slightly different), and business logic ends up scattered into infrastructure code (or vice versa) because nobody paused to check which one they were writing. Both mistakes are cheap to prevent up front and expensive to untangle later.

## Before starting

You need an approved test plan (from `writing-test-plan`) and the plan it came from (for the Contract details). Work through one task at a time, in the order the plan lists them.

## Step 1 — Discover the project's actual architecture

Before placing a single line of code, find out how *this* project is actually organized — don't assume a layout from habit or from a different project. Look for:

- Existing top-level or per-module directories that already separate business logic from technical concerns (`application/`, `domain/`, `modules/*/application`, `infrastructure/`, `adapters/`, etc. — names vary a lot).
- Any file that documents the convention directly — a `README`, `ARCHITECTURE.md`, contributing guide, or similar.
- If a project-specific architecture skill or rule already exists (for example a `backend-clean-architecture`-style skill, or a Kiro steering file in `.kiro/steering/` describing structure or conventions), follow it — this step is about finding ground truth, not overriding something the project already settled.

If the project is new and genuinely has no convention yet, propose one and confirm with the user before creating new top-level structure — don't silently invent a layout for someone else's project.

## Step 2 — Decide business logic vs infrastructure

For each piece of logic you're about to write, ask: **would this change because a business rule changed, or because a technology changed?**

- If a change in *requirements* would change this code — how many retry attempts are allowed, what counts as a valid discount, what order steps happen in — it's business logic. It belongs in the application/business layer.
- If a change in *tooling* would change this code — swapping Postgres for DynamoDB, Stripe for a different payment processor, REST for gRPC — it's infrastructure. It belongs in the infrastructure layer.

A second, more mechanical check: does this code import or directly depend on a specific external library, driver, SDK, or protocol (an ORM, an HTTP client, a queue client, a specific cloud SDK)? That's a strong signal it's infrastructure. Business logic should be expressible using only the project's own plain types and interfaces — it defines *what it needs* from the outside world (e.g. "something that can look up a payment by ID"), not *how* that need gets fulfilled.

This gives the dependency direction too: infrastructure depends on interfaces the business layer defines, never the other way around. If business logic ends up importing a concrete infrastructure class directly, that's a sign it's in the wrong place, or the interface boundary is missing.

Example:
- Deciding whether a payment is eligible for another retry, based on how many attempts have already happened → business logic.
- Actually calling the payment provider's API to charge the card → infrastructure.
- Looking up the payment's current retry count from the database → infrastructure (the query/storage mechanics), even though *what it's used for* is a business decision.

When unsure, err toward asking "if I had to swap the underlying tool tomorrow, would this line of code have to change?" — if yes, it's infrastructure.

## Step 3 — Write test code from the test plan

For every test case in the test plan, write exactly one test — one single test function/case in your framework (one `def test_...()`, one `it(...)`, one `@Test` method), not a group of several. Carry over its ID (e.g. `1.1`) into that test — either in its name (`test_1_1_reject_duplicate_retry`) if the framework's naming supports it, or as a comment/annotation directly above it — so anyone can match code back to plan later without guessing.

It's fine for that one test to contain more than one assertion when the test case's `Result:` describes more than one observable outcome (e.g. "rejected with 409 *and* the original retry is left untouched") — both assertions verify the same single scenario, so they stay in the same test. What matters is the 1:1 mapping at the test-case level: one test-plan ID, one test function. Keeping it 1:1 is what makes the cross-check in the next paragraph a simple lookup instead of a judgment call.

Translate the test case directly: its numbered setup/action steps become the arrange/act part of the test, and its `Result:` line becomes the assertion. Don't reinterpret or "improve" the scenario while writing it — if the test plan seems wrong or incomplete once you're looking at real code, stop and raise it with the user rather than quietly writing a different test than what was planned.

Once a task's tests are all written, cross-check them against that task's section of the test plan: every test-plan ID has exactly one test, and no test exists that doesn't trace back to an ID. If you believe an extra test is genuinely needed, say so and ask rather than adding it silently — the test plan is the agreed contract for this step.

## Step 4 — Confirm red

Run the tests you just wrote, before any implementation exists. Every one of them should fail — and it matters *why*:

- A failure because the behavior doesn't exist yet (an assertion failed, or the code under test doesn't exist) is a correct red. Good.
- A failure because of a typo, import error, or broken test setup is not a meaningful red — fix the test itself first.
- If a test unexpectedly **passes** with no implementation, stop before writing any code. Either the behavior already exists somewhere (this task may be redundant — check with the user) or the test isn't actually exercising the thing it claims to — a false positive that would give false confidence later.

## Step 5 — Implement, minimally, in the right place

Write just enough code to make the currently-red tests pass — resist building beyond what the test plan actually requires. Place each piece of logic using the Step 2 heuristic and the layout discovered in Step 1: business rules in the application/business layer, technical mechanics in infrastructure, with infrastructure depending on interfaces the application layer defines.

### Watch for these classes of bugs while implementing

These are the bugs that separate code that works in a demo from code that survives production traffic — none of them show up in a quick manual test, which is exactly why they're worth checking for deliberately. Apply them proportionally to what's actually at stake: a low-traffic internal tool doesn't need the same rigor as a payments ledger. When you can't tell which side of that line a piece of code falls on, or the safer option has a real cost (more latency, more complex code, lower throughput), ask the user instead of guessing — they know what this system actually needs to survive, you don't.

**N+1 queries.** If you're looping over a collection and issuing a separate query (a DB call, an API call) per item inside the loop, that's an N+1 — harmless for a handful of items that will never grow, a real problem for anything that scales with user data. Prefer fetching what's needed in one batched call (a join, an `IN (...)` query, a bulk loader) over querying inside a loop.

**Race conditions.** Whenever more than one request or process can act on the same resource concurrently, decide on purpose what should happen — don't let it be accidental. Ask: if two of these ran at the exact same instant, what's the correct outcome? Sometimes last-write-wins is genuinely fine — overwriting a "last seen" timestamp costs nothing if one update gets lost. Sometimes it isn't — two requests both decrementing the same inventory count, or both approving the same withdrawal, is a real bug. That needs an actual mechanism: an atomic database-level update, optimistic locking (a version check that rejects a stale write), or pessimistic locking (holding a row lock for the duration). If it's unclear which category a given resource falls into, ask rather than defaulting to whichever is easiest to code.

**Atomicity.** When one logical action involves multiple writes (several tables, or a write plus a side effect), decide what happens if it fails halfway through. If a partial completion would leave the system in a broken state — an order recorded but inventory never deducted — wrap the writes in a transaction so they succeed or fail together. When the writes span systems that can't share a transaction (your database and a third-party API), a transaction can't solve it — flag this to the user so they can decide on a compensating strategy (retry, reconciliation job, outbox pattern) rather than silently shipping the gap.

**Consistency.** Business rules often imply invariants that must always hold — a balance that can never go negative, a total that must always equal the sum of its parts. Make sure the implementation actually enforces these at a real boundary (a check before the write, a database constraint, a transaction) rather than trusting every code path to maintain them by convention. If eventual consistency is genuinely acceptable here (a cache that can lag by a few seconds, say), that's a fine choice — but make it a deliberate one, and say so, rather than something that falls out of the architecture by accident.

**Idempotency.** Anything that can be triggered more than once for what should be a single effect — a client retrying a timed-out request, a webhook getting redelivered, a user double-clicking submit — needs to behave safely on the second call. Decide what a duplicate call should do (reject it, silently return the original result, no-op) and make sure that's what actually happens, rather than assuming the caller will only ever call once. If the plan's Contract already specifies this (it often will, for exactly this reason), implement to that; if it doesn't and the task can plausibly be called twice, ask rather than picking a behavior silently.

**Timeouts on external calls.** Any call out to something you don't control — another service, the database, a queue — should have a timeout. Without one, a single slow or hung dependency can pile up requests and exhaust connections or threads for the whole system, turning one dependency's bad day into an outage of your own.

**Unbounded queries.** Loading an entire table or collection with no limit works fine while the data is small and quietly becomes a memory or latency problem as it grows. If a query's result size scales with user data over time, paginate it or cap it rather than assuming today's data volume is forever.

**Authorization on the resource, not just the request.** Checking that someone is logged in isn't the same as checking that they're allowed to touch the specific resource they're asking for — an endpoint that checks "is there a valid session" but not "does this session's user actually own the record being requested" will happily hand back someone else's data. Whenever an endpoint or function takes an identifier from the caller, confirm the caller is authorized for that specific instance, not just authorized to call the endpoint in general.

## Step 6 — Confirm green

Run the tests again. The task's tests should now all pass. If a test outside this task's scope starts failing, stop and look into it before continuing — that's a regression, not something to work around.

If the task's own tests are still failing, don't just keep patching and re-running on a hunch — read the failure and diagnose why before changing anything else. Give yourself at most 2-3 diagnosed attempts at a fix. If it's still red after that, stop and report to the user what's failing and what you've ruled out, rather than continuing to guess — repeated blind attempts are a sign the implementation approach or the test itself needs a second pair of eyes, not more iterations.

## Step 7 — Refactor

With tests green, clean up naming, duplication, or structure as needed. Re-run the tests after each small change to make sure they stay green throughout — refactoring should never require touching the tests themselves, since the observable behavior isn't changing.

If a refactor step turns a test red, don't iterate on it trying to force it back to green — revert that specific change immediately, since you know it was working before. Only re-attempt the refactor once you understand why it broke the test; if it's not obvious why, leave the code as it was and move on rather than looping on it.

## Between tasks

After a task goes green (and any refactor is done), report which test-plan IDs are now passing and stop before moving to the next task. This keeps the same rhythm as the rest of the plan: each task is a checkpoint, not something to blow through on the way to "done."
