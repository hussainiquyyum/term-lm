---
name: commit
description: Commit workflow for term-lm — inspects the working tree, runs `just check`, proposes a lowercase conventional commit, and stages only intended files, with guards for secrets and local-only config.
disable-model-invocation: true
---

# Commit Workflow

term-lm is a **single git repository** (Cargo workspace: root crate `term-lm` + `crates/ghostty-vt`). Vendored code lives under `vendor/` and is part of this repo.

## Hard rules

- **Never stage `.env` / `.env.*`, `.claude/settings.local.json`, credentials, or build output** (`target/`, `.zig-cache/`, `.local/`, `backlog`). If one shows up in `git status`, leave it alone and tell the user.
- **Ask for explicit confirmation before every `git commit`.** Show the exact file list and the proposed message first, then wait for a yes.
- **Never `git push` unless the user explicitly asks in this conversation.** Earlier approval does not carry over.
- **No AI attribution** in commit messages, trailers, branch names or author metadata. No `Co-Authored-By` unless the user gives a human co-author.
- **Never bypass checks** (`--no-verify`, skipping `just check`). Fix the failure, or tell the user exactly why a narrower check is enough (AGENTS.md: run `just check` before committing unless the project owner explicitly accepts narrower validation).
- If `git status` contradicts what the user described (unexpected deletions, unfamiliar files), surface it before committing.

## Commit message format

Lowercase conventional commits, no emojis (AGENTS.md, CONTRIBUTING.md, enforced by CI on subjects and PR titles):

```
<type>: <descriptive subject>
<type>(<scope>): <descriptive subject>
```

- **type** — lowercase, one of: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `style`, `build`, `ci`, `perf`
- **scope** — optional, a module such as `detect`, `api`, `protocol`, `app`, `platform`, `vendor`
- **subject** — imperative, lowercase, descriptive, no trailing period

Examples: `fix: handle pane focus`, `feat(detect): add kiro idle gate`, `chore(vendor): reapply libghostty-vt patch`.

## Workflow

### 1. Inspect

Run `git status --porcelain` and `git branch --show-current`. Report what changed, grouped by area (`src/`, `crates/`, `src/detect/manifests/`, `distribution/`, `vendor/`, `docs/`, `scripts/`, CI).

### 2. Check for coupled changes

Flag these before committing, since AGENTS.md ties them together:

- `src/detect/manifests/<agent>.toml` changed for an already released agent → `distribution/agent-detection/` must stay aligned (or the validator needs a recorded exception).
- Wire/API/protocol change (`src/protocol/`, `src/api/schema/`, fixtures) → check the stable endpoint contract and `PROTOCOL_VERSION` rule; never edit generation-1 fixtures to bless a change.
- `vendor/libghostty-vt` changed → `vendor/libghostty-vt.patches.md` and `vendor/patches/libghostty-vt/` must match.
- Integration assets changed → `*_INTEGRATION_VERSION` bumped once relative to the latest released tag.
- Render, layout, PTY parsing or detection work added → performance evidence per AGENTS.md (`just bench-render-scale`).

Offer the `wire-compat-reviewer` / `hot-path-reviewer` agents when the diff touches those areas.

### 3. Validate

Run `just check` (formatting, nextest, maintenance tests, Windows lint when the SDK is set up). Report failures with output; do not commit on red unless the user explicitly accepts narrower validation.

### 4. Propose and commit

1. Show the file list and proposed message.
2. Wait for confirmation.
3. Stage only the intended files (no blanket `git add -A` when excluded files are present).
4. Commit with the approved message exactly as shown. The repo's pre-commit hook runs `just lint`; if it fails, fix and make a **new** commit rather than amending.
5. Do not push.

Split unrelated changes into separate commits.

### 5. Close out

Summarize short hash + message for each commit and remind the user that nothing was pushed.
