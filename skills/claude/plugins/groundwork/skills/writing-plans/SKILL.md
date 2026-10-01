---
name: writing-plans
description: Use this once the problem is understood (typically right after a discovery/mental-model step) and it's time to turn it into a concrete plan before writing any code. Produces a short, plain-English plan file — overview, goals, a task breakdown with a goal and workflow per task, and an explicit out-of-scope list — saved to plans/ so it can be reviewed and later followed by an execution step. Trigger for "let's plan this out", "break this into tasks", "write a plan for X", or any multi-step coding work about to start. Do NOT use for a single, obvious, one-step change — planning ceremony for a one-line fix just adds friction.
---

# Writing Plans

## What this is for

A plan exists so that before anyone writes a line of code, both you and the user agree on *what* is going to be built and in *what order* — not on the exact implementation. A plan full of function signatures and code snippets is really a first draft of the implementation wearing a plan's clothes; it's slower to review, harder to change your mind about, and it hides the one thing a plan should make obvious: the shape of the work. Keep every part of the plan in plain English. The "how" comes later, when the plan is actually executed.

## Before writing the plan

Make sure the problem itself is already understood — the mental model from discovery is confirmed, or the request is simple enough that there's nothing left to clarify. If it isn't, that's the discovery step's job, not this one; don't use plan-writing to paper over a fuzzy understanding of the problem.

## Structure

Every plan follows this shape:

```markdown
# <Plan title>

## Overview
A few sentences: what this plan is for and why, in plain language.

## Goal
The overall outcome this plan needs to achieve. What does "done" look like, described as an outcome — not a list of steps.

## Assumptions
Things this plan takes for granted — if one of these turns out to be false, the plan itself needs to change, not just a task. Skip this section entirely if there's genuinely nothing to flag.
- ...

## Tasks

### Task 1: <short task name>
**Goal:** what this specific task achieves on its own.
**Contract:** (only when this task creates or changes something other code/people will call) the input/output shape of that boundary.
**Workflow:**
1. First plain-English step of what gets built/changed.
2. Next step, in the order it should happen.
3. ...

### Task 2: <short task name>
**Goal:** ...
**Workflow:**
1. ...

## Out of scope
- Things this plan deliberately does not cover, so no one — human or AI — quietly wanders into them mid-execution.
```

List tasks in the order they should be done — the order in the list *is* the execution order, no separate dependency diagram needed.

### Writing Assumptions

An assumption is something the plan is relying on without verifying — "the auth service already returns a stable user ID", "this only needs to handle USD". These aren't goals and they aren't tasks; they're the ground the plan is standing on. Write them down because if one is wrong, it's cheaper to find out now, from a five-second read, than after several tasks are built on top of it. Most plans only have one or two, if any — don't manufacture assumptions just to fill the section, and skip it entirely when there's nothing worth flagging.

### Writing a task's Contract

A contract is the shape of a boundary something else will call or depend on: an API endpoint, a function signature other code will use, an event payload, a CLI flag, a database schema change. It's different from the Workflow in kind, not just detail — the workflow is a sequence of steps, the contract is a fixed shape that has to be pinned down precisely because getting it wrong is expensive to fix later (other code will already be written against it). That precision is why it gets its own line instead of being folded into a Goal written in looser prose.

Only add a Contract to a task that actually introduces or changes one of these boundaries. A task like "refactor internal helper" or "clean up logging" has nothing to put here — leave the line out entirely rather than writing "N/A".

Keep it to the shape, not the reasoning behind it — inputs, outputs, and the error/edge cases that are part of the same boundary:

Good:
> **Contract:** `POST /payments/:id/retry`, no body. Returns `200` with `{ retryScheduledAt }`, or `409` if a retry is already pending.

Bad (this is now describing internals, not the boundary):
> **Contract:** Calls `RetryPolicy.schedule()` which pushes onto the `retry_queue` Redis list with a computed TTL...

### Flag concurrency and data-integrity decisions while planning

Some tasks touch things that go wrong in ways that are easy to miss until code already exists: a resource more than one request could act on at the same time, an action that might get triggered twice for what should be a single effect (a retried request, a redelivered webhook), or a step that only makes sense if several writes succeed or fail together. These are business decisions, not implementation details — whether a duplicate retry gets silently ignored or rejected outright changes what the API *is*, not just how it's coded. Deciding it now, with the user, is cheaper than leaving it for whoever implements the task to guess.

While writing a task, check whether it has one of these shapes, and if it does, raise it with the user before finalizing the plan:

- Could this be called more than once for what should be a single effect (retries, webhooks, double-clicks)? Decide what a duplicate call should do, and put it in the task's Contract — this is exactly the kind of thing that belongs in a `409` or similar response, as in the example above.
- Could two requests act on the same resource at the same time? Decide whether that's fine as-is (last-write-wins) or needs to be prevented, and note whichever it is — in the Contract if it changes the boundary's behavior, in Assumptions if it's a decision that applies more broadly than one task.
- Does this task write to more than one place as one logical action? Decide whether partial failure is acceptable, and note it if that isn't already obvious from the Workflow.

Most tasks are none of these — a task that reads one row once has nothing to flag here. Only raise it when a task genuinely has one of these shapes; asking about locking strategy for a simple read is the same kind of overthinking this whole kit exists to avoid.

### Writing a task's Workflow

The workflow is the sequence of what gets built, not how. Naming a specific file, class, or module is fine when it helps locate the work (e.g. "add a retry check in the payment handler") — but stop there. Don't describe the internals of a function, the exact library call, or a code snippet; that's implementation, and belongs to the execution step, not the plan.

Good:
> 1. Add a check before charging that looks up whether this payment already has a pending retry.
> 2. If a retry is scheduled, skip charging and log why instead.
> 3. Wire the webhook handler to clear the retry once a charge succeeds.

Bad (this is implementation, not a plan):
> 1. Add `if retry_queue.exists(payment_id): return` at the top of `charge()`.
> 2. Call `logger.info(f"skipped retry for {payment_id}")`.
> 3. In `handle_webhook()`, call `retry_queue.delete(payment_id)` inside the `charge.succeeded` branch.

If a task's workflow is ballooning into many steps that don't share one clear goal, that's usually a sign it's actually two tasks — split it. A task should be small enough that "is this task done?" has an obvious yes/no answer.

## Saving the plan

Get the real current date and time from the system (e.g. run `date +%Y-%m-%d-%H%M`) — never guess or estimate it.

Save the plan to:

```
plans/<YYYY-MM-DD-HHmm>-<slug>.md
```

- Create the `plans/` directory at the project root if it doesn't exist yet.
- `<slug>` is a short kebab-case name (3-6 words) describing what the plan is about, drawn from the Goal — not a generic name like `plan` or `update`. Example: `2026-08-26-1430-add-payment-retry.md`.

## After saving

Tell the user where the plan was saved, then give a short recap — the Overview and the task names/goals are usually enough, not the full file contents again since they can open it. Then stop. Don't move on to executing the plan or writing code until the user has reviewed it and says to proceed; they may want to reorder, merge, split, or cut tasks first, and building on top of an unapproved plan risks redoing the work.
