---
name: writing-test-plan
description: Use this after a plan (from writing-plans) has been approved and before writing any test code or implementation, when the team is working test-driven. Turns the plan into a plain-English test plan — one set of test cases per task, each written as a concrete numbered scenario (setup and action steps ending in the expected result) — saved alongside the plan so the next step (writing the actual failing tests, then the code to pass them) has something concrete to follow. Trigger for "let's write the tests for this plan", "what should we test before coding this", or any point where a plan exists and TDD is the approach. Do NOT use this to write actual test code (assertions, test framework syntax) — that belongs to the implementation step, not this one.
license: MIT
metadata:
  author: "Dũng"
  version: "0.2.0"
  kit: groundwork
---

# Writing Test Plan

## What this is for

In test-driven development, the tests are supposed to define what "correct" means before any implementation exists. That definition should be something a person can read and agree with in plain language — "if you send a retry request while one is already pending, it should be rejected" — before it's translated into `assertEquals` and framework syntax. A test plan is that plain-language definition, written down so both the reviewer and whoever writes the actual test code later are working from the same understanding of what needs to be true.

Keep this the same way as a plan: what needs to be verified and how you'd know it worked, not the test code itself. If you catch yourself writing `expect(...)`, mock setup, or framework-specific syntax, that's the next step's job, not this one.

A test case earns its place here only if someone could read it and go run it by hand — click the buttons, make the calls, check the outcome — without needing to see any code first. If a step is vague enough that two people could carry it out differently, it isn't done yet.

## Before writing the test plan

You need an approved plan (from `writing-plans`) to work from — read the plan file in `plans/`. Each task's Goal, Contract (if it has one), and Workflow are what test cases are derived from: the Goal says what should end up being true, the Contract (when present) pins down the exact boundary behavior including its error cases, and the Workflow hints at what could go wrong at each step.

## Structure

One test-plan file per plan, organized by the same tasks:

```markdown
# Test Plan: <Plan title>
Plan: plans/<same-timestamp>-<same-slug>.md

## Task 1: <task name, matching the plan>

### 1.1 <short test case title>
<one-line description of what this test case is checking>
**Type:** happy path
**Workflow:**
1. <setup or action, in plain English>
2. <next action>
3. ...
4. Result: <the expected outcome — this is what makes the test pass or fail>

### 1.2 <short test case title>
...
**Type:** edge case
**Workflow:**
1. ...
Result: ...

## Task 2: <task name, matching the plan>

### 2.1 <short test case title>
...
**Type:** error case
**Workflow:**
1. ...
Result: ...
```

Number test cases `<task number>.<test number>` so they can be referenced unambiguously later (e.g. "test 2.1 is still failing"). `Result:` is always the last line of the Workflow, never a separate field — reading the whole numbered list top to bottom should feel like one continuous scenario ending in an outcome, not a setup paragraph followed by a separate verdict.

### Choosing test cases per task

For each task, cover at minimum: the happy path (the thing working as intended), and any edge or error case that the task's Goal, Contract, or Workflow implies matters. A task with a Contract almost always needs one test case per distinct response in that contract — if the contract says "409 if a retry is already pending," that's its own error-case test, not a footnote on the happy-path test. A task with no Contract still needs at least the happy path, plus whatever edge cases are obvious from its Goal.

Don't pad the list with test cases that don't correspond to anything in the task — every test case should trace back to something the Goal, Contract, or Workflow actually implies needs to hold.

### Writing a test case's Workflow

Break the scenario into discrete numbered steps — each one a concrete action or piece of setup, in the order it actually happens — ending in a `Result:` line that states the observable outcome. Don't compress the scenario into a summary paragraph; a reader should be able to follow the steps one at a time and know exactly what to do at each one, the way a manual test case reads.

Each step should be specific enough that two different people would carry it out the same way, without needing literal sample data (exact IDs, real JSON bodies) unless a specific value is actually what's being tested — the point is removing ambiguity about *what happens*, not supplying copy-pasteable fixtures for the next step.

Good:
> **Workflow:**
> 1. Set up a payment that already has a retry scheduled.
> 2. Attempt to trigger another retry on that same payment.
> 3. Result: the second attempt is rejected instead of being scheduled, and the original scheduled retry is left untouched.

Bad — collapsed into a summary instead of steps:
> **Workflow:** Given a payment that already has a retry scheduled, attempt another retry and expect it to be rejected.

Bad — this is test code, not a plan:
> 1. `payment = create_payment(status="pending_retry")`
> 2. `response = client.post(f"/payments/{payment.id}/retry")`
> 3. Result: `assert response.status_code == 409`

Bad — the result is too vague to actually verify:
> 3. Result: the retry logic works correctly.

## Saving the test plan

Use the exact same date-time and slug as the plan it's derived from — don't generate a new timestamp. Save to:

```
plans/<YYYY-MM-DD-HHmm>-<slug>-test-plan.md
```

So a plan at `plans/2026-08-26-1430-add-payment-retry.md` produces `plans/2026-08-26-1430-add-payment-retry-test-plan.md`.

## After saving

Tell the user where the test plan was saved, and give a short recap — how many test cases per task is usually enough, not the full file again. Then stop. Don't start writing actual test code or implementation until the user has reviewed the test plan; they may spot a missing case or disagree with an expected result, and that's much cheaper to fix here than after tests are already written against it.
