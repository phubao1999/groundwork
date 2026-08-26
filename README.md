# groundwork

A personal Claude Code skill kit for programming work — built to replace the `superpowers` plugin.

Five skills, chained together:

- `feature-development` — entry point. Figures out whether a request is new work or a continuation of something already in progress, then routes into the rest.
- `discovery` — clarifies an ambiguous request: confirms where to look for missing context, then reports back a plain-English mental model before any technical detail.
- `writing-plans` — turns an understood problem into a short plan (`plans/<timestamp>-<slug>.md`): overview, goal, assumptions, per-task goal/contract/workflow, out of scope.
- `writing-test-plan` — turns an approved plan into a plain-English test plan (`plans/<timestamp>-<slug>-test-plan.md`), one concrete step-by-step scenario per test case.
- `test-driven-development` — implements from the test plan: red → green → refactor, tests traceable to test-plan IDs, code placed in the right architectural layer (business vs infrastructure), with a checklist for concurrency/scale correctness (N+1, race conditions, atomicity, consistency, idempotency, timeouts, unbounded queries, authorization).

## Install on a new machine

```bash
# one-time per machine
/plugin marketplace add git@github.com:phamtrungdungdhsp/groundwork.git
/plugin install groundwork@groundwork
```

## Update after editing a skill

Push your changes to the git remote, then on each machine:

```bash
/plugin marketplace update groundwork
/plugin update groundwork
```

(exact update subcommands may vary by Claude Code version — check `/plugin help` if these don't match)

## Repo layout

```
.claude-plugin/marketplace.json   <- lists the plugin below
plugins/groundwork/
  .claude-plugin/plugin.json
  skills/
    feature-development/SKILL.md
    discovery/SKILL.md
    writing-plans/SKILL.md
    writing-test-plan/SKILL.md
    test-driven-development/SKILL.md
```

To add a new skill to the kit later: create `plugins/groundwork/skills/<name>/SKILL.md`, bump the `version` in `plugins/groundwork/.claude-plugin/plugin.json`, commit, push, and run the update commands above on each machine.
