# groundwork
A personal skill kit for programming work, in two flavors of the same five skills:
- `skills/kiro/` — for [Kiro](https://kiro.dev), in the [Agent Skills](https://agentskills.io/specification) format (`skills/kiro/<name>/SKILL.md`).
- `skills/claude/` — the original Claude Code plugin (`.claude-plugin` manifests plus `plugins/groundwork/skills/`).

Both describe the same workflow; pick the folder that matches your tool. Each has its own installer: `install.kiro.sh` for Kiro, `install.sh` for Claude Code.

Five skills, chained together:
- `feature-development` — entry point. Figures out whether a request is new work or a continuation of something already in progress (in `plans/` or `.kiro/specs/`), then routes into the rest.
- `discovery` — clarifies an ambiguous request: confirms where to look for missing context, then reports back a plain-English mental model before any technical detail.
- `writing-plans` — turns an understood problem into a short plan (`plans/<timestamp>-<slug>.md`): overview, goal, assumptions, per-task goal/contract/workflow, out of scope.
- `writing-test-plan` — turns an approved plan into a plain-English test plan (`plans/<timestamp>-<slug>-test-plan.md`), one concrete step-by-step scenario per test case.
- `test-driven-development` — implements from the test plan: red → green → refactor, tests traceable to test-plan IDs, code placed in the right architectural layer (business vs infrastructure), with a checklist for concurrency/scale correctness (N+1, race conditions, atomicity, consistency, idempotency, timeouts, unbounded queries, authorization).

Kiro loads a skill automatically when your request matches its description. You can also run one directly as a slash command in chat, e.g. `/feature-development add payment retries`.

## Install on Kiro

Install them all at once. `feature-development` hands off to the other four.

```bash
git clone https://github.com/phamtrungdungdhsp/groundwork.git ~/groundwork
cd ~/groundwork

./install.kiro.sh                          # global: every project (~/.kiro/skills)
./install.kiro.sh --project ~/code/my-app  # a single project (<project>/.kiro/skills)
```

By default the script creates symlinks, so a `git pull` in this repo updates every install. Add `--copy` to copy the files instead, e.g. when you want to commit the skills into a project repo. Run `./install.kiro.sh --uninstall` with the same options to remove them. Start a new chat session afterwards so Kiro picks up the changes.

You can also use the Kiro IDE: open the Kiro panel → **Agent Steering & Skills** → **+** → **Import a skill**, then pick a local folder or a GitHub URL. The URL has to point at a single skill folder (e.g. `.../tree/main/skills/kiro/discovery`), so you need one import per skill. Imported skills are copied, which means they won't update when this repo changes.

If a project skill and a global skill share a name, the project one wins.

Custom Kiro agents don't load skills by default. Add them to the agent's `resources`:
```json
"resources": ["skill://~/.kiro/skills/*/SKILL.md"]
```

## Install on Claude Code

The `skills/claude/` folder is a self-contained Claude Code plugin marketplace. From a local checkout:

```bash
git clone https://github.com/phamtrungdungdhsp/groundwork.git ~/groundwork
cd ~/groundwork

./install.sh              # register the marketplace and install the plugin
./install.sh --uninstall  # remove the plugin and the marketplace
```

`install.sh` wraps the `claude plugin` CLI: it validates `skills/claude`, registers it as a local marketplace, and installs the `groundwork` plugin from it. Edits to `skills/claude` take effect on the next session or after `/reload-plugins`.

Prefer to do it by hand, or install straight from the git remote? Run the equivalent inside Claude Code:

```
/plugin marketplace add git@github.com:phamtrungdungdhsp/groundwork.git
/plugin install groundwork@groundwork
```

If Claude Code can't find the marketplace at the repo root, point it at the `skills/claude` subfolder (the one holding `.claude-plugin/marketplace.json`). To update after editing a skill, push your changes and run `/plugin marketplace update groundwork` then `/plugin update groundwork` (exact subcommands vary by version — check `/plugin help`).

## Repo layout
```
install.kiro.sh                       <- installs the Kiro skills (skills/kiro)
install.sh                            <- installs the Claude plugin (skills/claude)
skills/
  kiro/                               <- Kiro Agent Skills
    feature-development/SKILL.md
    discovery/SKILL.md
    writing-plans/SKILL.md
    writing-test-plan/SKILL.md
    test-driven-development/SKILL.md
  claude/                             <- Claude Code plugin
    .claude-plugin/marketplace.json
    plugins/groundwork/
      .claude-plugin/plugin.json
      skills/<five skills>/SKILL.md
```

To add a Kiro skill: create `skills/kiro/<name>/SKILL.md`. The `name` in the frontmatter has to match the folder name (lowercase, digits and hyphens, at most 64 characters). The `description` can be up to 1024 characters. Add `kit: groundwork` under `metadata` so `install.kiro.sh` recognizes the skill as its own. Then bump `metadata.version`, commit, and push. Symlinked installs pick it up after `git pull` plus a re-run of `./install.kiro.sh`, which links any new folders. The two folders are maintained independently — a change to a Kiro skill isn't automatically mirrored into the Claude copy, so update both if you want them to stay in sync.
