---
name: feature-development
description: "Use this whenever a coding request is more than a trivial one-step change — a new feature, a non-obvious bug fix, a refactor, anything where jumping straight to code risks solving the wrong problem. This is the entry point for the whole development kit (discovery, writing-plans, writing-test-plan, test-driven-development) — it works out whether the request is brand new or a continuation of work already in progress (an existing plan or test plan in plans/), then routes into whichever of those skills should run next, in order, stopping at each one's own checkpoint. Trigger for 'let's build X', 'implement Y', 'can you add...', 'let's keep working on...', or picking up a ticket/task. Do NOT use for a genuinely trivial change (a typo, a one-line config tweak, an exact known fix) — just make the change."
---

# Feature Development

## What this is for

Left alone, a coding assistant tends to do one of two unhelpful things: jump straight into writing code before the problem or the plan is actually settled, or — on the other side — restart the whole ceremony from scratch every time, even when a plan and test plan already exist from an earlier session and all that's left is to keep implementing. This skill exists to make that judgment call correctly: figure out where a piece of work actually stands, then continue from there through the right sequence of skills — `discovery` → `writing-plans` → `writing-test-plan` → `test-driven-development` — rather than guessing.

This skill doesn't replace any of those four; it decides which one(s) still need to run and hands off to them. Each of them already knows how to do its own job and already stops for confirmation at the right point — this skill's only job is figuring out where to start.

## Step 1 — Figure out where this request actually stands

Before doing anything else, check `plans/` for anything that looks related to the current request — match on topic, not just recency (a request about payment retries should be checked against a plan about payment retries, not just whatever the newest file happens to be).

Don't assume what you find is further along than it is — a plan file existing doesn't mean it was approved, and a test-plan file existing doesn't mean anyone reviewed it. If it's not obvious from the conversation itself, say what you found and confirm rather than guessing:

- **Nothing related exists** → this is new work. Start at `discovery`.
- **A plan exists, no test plan yet** → the planning step is likely done. Confirm briefly ("found a plan for payment retries at `plans/...` — should we pick up from writing the test plan?") rather than silently assuming it was approved, then continue to `writing-test-plan`.
- **Both a plan and a test plan exist** → implementation is likely underway or about to start. Check which tasks/tests already have passing code (read the code and run the existing tests if any exist) to find out which task to resume at, confirm that with the user, then continue in `test-driven-development` from there.
- **Genuinely ambiguous** (e.g. multiple plans could match, or what exists looks abandoned/outdated) → just ask. Guessing wrong here wastes more time than one quick question.

## Step 2 — Hand off and chain through

Once you know the starting point, invoke that skill. When it finishes and the user approves its output, move to the next skill in the sequence yourself rather than waiting to be asked again — the point of this skill is that the user shouldn't have to manually invoke each of the four in turn. Each skill's own stop-and-wait checkpoint still applies; this skill only removes the need to separately decide "what do I run next."

The sequence is fixed: `discovery` → `writing-plans` → `writing-test-plan` → `test-driven-development`. Don't skip a stage just because the work feels simple enough to shortcut — each stage has its own escape hatch for genuinely trivial cases (for example, `writing-plans` already says not to bother planning a one-line change), so trust those rather than second-guessing the sequence from here.

## As the kit grows

This is the place to note how other skills in the kit fit around this core sequence once they exist — for example, where a debugging skill gets used when a test fails in a way `test-driven-development`'s own red/green checks don't explain, or where a code-review skill fits in after a task goes green. Update this section as those get added, so this skill stays the one place that describes the whole shape of the kit.
