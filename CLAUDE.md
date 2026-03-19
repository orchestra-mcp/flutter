# CLAUDE.md

This project uses [Orchestra MCP](https://github.com/orchestra-mcp/framework) for AI-powered project management.

## Mandatory Workflow Rule

**ALL work MUST go through Orchestra MCP tools.** When the user asks you to do ANY task — build, fix, test, refactor, document, investigate, or change anything:

1. `search_features` / `list_features` — check for existing feature
2. `create_feature` — create one if needed (with `kind`: feature/bug/hotfix/chore)
3. `set_current_feature` — start work (moves to in-progress)
4. Do the work
5. `advance_feature` — pass gates with structured evidence
6. `request_review` + `AskUserQuestion` — get user approval
7. `submit_review` — complete

**Never do any work without an active feature.** This includes running tests, writing docs, investigating bugs, and refactoring. The MCP enforces gated transitions — you cannot advance without evidence.

### Feature Kinds

Every feature has a `kind` field: `feature` (default), `bug`, `hotfix`, or `chore`.

- **feature** — New functionality or enhancement
- **bug** — Defect report (Gate 3/docs skipped automatically)
- **hotfix** — Urgent fix (Gate 3/docs skipped automatically)
- **chore** — Maintenance, refactoring, CI work
- **testcase** — QA test case linked to a parent feature (Gate 3/docs skipped automatically)

Use `create_bug_report` as a shortcut for bugs. Use `create_test_case` or `bulk_create_test_cases` for QA test cases linked to a feature.

### Plan-First for Large Tasks (MANDATORY)

When a user request would result in **3 or more features**, you MUST create a plan before implementation:

1. `create_plan` — Create the plan in `draft` status with title and description
2. Present the plan to the user via `AskUserQuestion` for approval
3. `approve_plan` — Move from draft → approved
4. `breakdown_plan` — Break the plan into features with dependencies (pass a JSON array of feature definitions). This auto-creates all features with `plan:{plan_id}` labels and sets up dependency chains. Plan moves to `in-progress`.
5. Work each feature through the full lifecycle (in order of dependencies)
6. `complete_plan` — After all linked features are `done`, mark the plan as completed

**Do NOT skip the plan step for large tasks.** The plan is stored via MCP and provides traceability.

### User Request Queue

When the user sends a new request while you are busy working on a feature:

1. `create_request` — Save it to the queue with kind (feature/hotfix/bug) and priority
2. Continue working on the current feature
3. After the current feature reaches `done`, call `get_next_request` to pick up the next queued request
4. `convert_request` — Convert it into a feature (auto-creates with correct kind/priority)
5. Work the new feature through the full lifecycle

Use `list_requests` to see the queue and `dismiss_request` to discard irrelevant requests.

### Bug Reporting

When a completed feature causes a regression or breakage:

1. `create_bug_report` — Creates a feature with kind=bug, links to the original feature via `related_feature` param
2. The bug follows the same workflow but **Gate 3 (docs) is auto-skipped** for bugs and hotfixes
3. Work the bug through: backlog → todo → in-progress → testing → review → done

### Enforced Gates (MCP validates evidence)

The MCP **rejects** `advance_feature` if evidence is missing or malformed at gated transitions. Evidence must be markdown with `## Section` headers, each with at least 10 characters of content. **Sections marked with (files) must contain actual file paths** — not just prose.

| Gate | Transition | Required Sections | Tool | Skippable |
|------|-----------|-------------------|------|----------|
| 1 | in-progress → ready-for-testing | `## Summary`, `## Changes` **(files)**, `## Verification` | `advance_feature` | No |
| 2 | in-testing → ready-for-docs | `## Summary`, `## Results`, `## Coverage` | `advance_feature` | No |
| 3 | in-docs → documented | `## Summary`, `## Location` **(files)** | `advance_feature` | **Yes** (bug, hotfix) |
| 4 | documented → in-review | `## Summary`, `## Quality`, `## Checklist` **(files)** | `request_review` | No |
| 5 | in-review → done | User approval via `AskUserQuestion` | `submit_review` | No |

**Gate evidence format:**
```
evidence: "## Summary\n<what was done>\n\n## Changes\n- libs/foo/bar.go (added validation)\n- libs/baz/qux.go (new file)\n\n## Verification\n<how to test>"
```

Call `get_gate_requirements` to see what's needed for the next transition.

### Free Transitions (no gate)

These transitions can be done without evidence:
- backlog → todo, todo → in-progress, ready-for-testing → in-testing, ready-for-docs → in-docs, needs-edits → in-progress

### Review Flow (Gate 4-5)

1. Call `request_review` with self-review evidence (sections: `## Summary`, `## Quality`, `## Checklist`)
2. MCP moves feature to `in-review` and instructs you to ask the user
3. Use `AskUserQuestion` to present the review to the user with options: "Approve" / "Needs Edits"
4. Call `submit_review` with the user's decision (`status: "approved"` or `status: "needs-edits"`)

**Do NOT call `submit_review` without user approval.** `advance_feature` is blocked from `in-review` — you must use `submit_review`.

### Sub-Agent Rules

Sub-agents (Task tool) do **NOT** have MCP access. They cannot call `advance_feature` or any workflow tool.

- Sub-agents = code only (use during in-progress for writing code)
- Main agent owns lifecycle (YOU handle all gates: test, document, review)
- One feature at a time per assignee (complete full lifecycle before picking next)
- Summarize to user (tell user what sub-agent built before advancing)

### Anti-Patterns (NEVER DO)

- Batch-advancing multiple features through gates in rapid succession
- Writing fake/boilerplate evidence without doing actual work
- Advancing through gates without providing evidence that references real file paths
- Requesting review for one feature then starting another before review resolves
- Calling `submit_review` without asking the user via `AskUserQuestion` first

### Programmatic Guardrails (MCP-Enforced)

These rules are enforced at the MCP tool level — violation attempts return errors:

1. **One feature at a time per assignee** — `set_current_feature` blocks if the same assignee already has an active feature (in-progress through in-review). Different assignees (parallel agents) can each work on their own feature. Returns `wip_violation` error.
2. **Gate cooldown (30 seconds)** — Gated transitions require at least 30s since the last status change. Prevents instant batch-advancement. Returns `gate_cooldown` error.
3. **File path evidence** — Gate 1 (Changes), Gate 3 (Location), and Gate 4 (Checklist) sections must reference actual file paths. Returns `gate_blocked` error.
4. **Timestamped audit trail** — Every transition appends an ISO-8601 timestamp to the feature body for post-hoc review.
5. **Model capability check** — `set_current_feature` accepts a `model` parameter. Validates the model can handle the feature's size estimate (Haiku→S, Sonnet→S/M, Opus→S/M/L/XL). Returns `model_capability` error.
6. **Review requires user approval** — `advance_feature` is blocked from `in-review`. Only `submit_review` can move to `done`.

## Git & Sync (Natural Language Mapping)

The MCP provides 6 git tools that use the current user's person profile for author identity. **Map natural language requests to these tools automatically:**

| User says | Action |
|-----------|--------|
| "sync my changes", "push my updates", "sync to cloud" | `git_quick_commit` (stage all + commit) → `git_push` |
| "get latest", "pull updates", "sync from cloud" | `git_pull` |
| "save my work", "commit this" | `git_quick_commit` |
| "push", "push to remote" | `git_push` |
| "create a branch for X" | `git_create_branch` |
| "merge X" | `git_merge_branch` |
| "what's the status", "git status" | `git_status_summary` |
| "pull and rebase" | `git_pull` with `rebase: true` |

When the user says "sync" without a specific message, generate a meaningful commit message from the staged changes. All commits use the current user's person profile (name + github_email). No `Co-Authored-By` lines.

## Onboarding (First Interaction)

On the first interaction with a new user, check `get_current_user`. If not configured:

1. Use `AskUserQuestion` to collect: name, role, email, github_email, bio, timezone
2. `create_person` with the collected profile data
3. `set_current_user` to link them to the project
4. Confirm the setup — the profile persists in `~/.orchestra/me.json` across sessions

## Available Tools

Orchestra provides **85 tools** via MCP (70 feature workflow + 15 marketplace) and **5 prompts**.

Run `orchestra serve` to start the MCP server. IDE config is in `.mcp.json`.

## Installed Packs

No packs installed. Run `orchestra pack recommend` to get suggestions.

## Skills (Slash Commands)

| Command | Source |
|---------|--------|
| `/project-manager` | .claude/skills/project-manager/ |

## Agents

Specialized agents in `.claude/agents/` auto-delegate based on task context.

| Agent | File |
|-------|------|
| `orchestra` | .claude/agents/orchestra.md |

## Hooks

No hooks installed.
