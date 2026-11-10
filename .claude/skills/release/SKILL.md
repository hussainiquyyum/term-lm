---
name: release
description: Prepare and validate a term-lm release — version/contract checks, `just check`, release perf smoke, artifact builds, and the stable vs preview update-manifest rules from AGENTS.md. Use when the user wants to cut a version, ship a preview or stable build, or asks what must be true before releasing.
disable-model-invocation: true
argument-hint: "[version] [stable|preview]"
allowed-tools: Read Grep Glob Bash
---

# Release term-lm (`/release`)

term-lm is a single Rust binary (`Cargo.toml` `version`) distributed through install scripts (`distribution/install.sh`, `install.ps1`, `install.cmd`) with **stable** and **preview** update channels. Updaters read per-channel update manifests that advertise `endpoint_generation`.

**What this repo does not contain:** a tag-triggered publish workflow. The workflows present are `ci.yml` (checks), `nix.yml`, `windows-arm64.yml` and `build-artifacts-manual.yml` (`workflow_dispatch` that builds Linux/macOS/Windows artifacts). Publishing artifacts and update manifests happens outside this repo, so this skill prepares and validates a release but **does not publish one**. Do not invent a deploy step; ask the user how the release is published.

## Rules

- Never tag, push, publish, or trigger a workflow without explicit confirmation in this conversation.
- Never bypass a failing check. Report the output.
- The branch name in `ci.yml`/`nix.yml` is `master`; the local branch may differ. Confirm the release branch with the user.

## Step 1 — Preflight (local)

1. Clean tree, branch synced with `origin`: `git status --porcelain`, `git fetch`, `git log origin/<branch>..HEAD`.
2. `just check` (formatting, nextest, maintenance tests, Windows MSVC lint).
3. Release docs: `just lint` reminds you to update user-facing release docs. Confirm they are updated or called out.

## Step 2 — Contract checks (read AGENTS.md sections as needed)

Compare against the **latest released tag** for each item:

| Area | Rule |
|---|---|
| Wire protocol | Bump `src/protocol/wire.rs::PROTOCOL_VERSION` only if the current protocol was already published in stable or preview **and** the format changed incompatibly. Update hardcoded expectations/fixtures. |
| Client endpoint | Generation 1 stays available. Frozen codecs, bincode digests, wire-tag tests and `tests/fixtures/endpoint-method-shapes-v1.json` are not edited to bless a change. |
| Update manifests | Stable and preview manifests advertise `endpoint_generation`; keep release tooling aligned so older updaters know when a new server generation requires replacement. |
| Integration assets | `TERMLM_INTEGRATION_VERSION` markers and `*_INTEGRATION_VERSION` constants are bumped **once** from the latest release version, not per commit. |
| Agent detection | `distribution/agent-detection/` matches bundled `src/detect/manifests/` for released agents (or a recorded validator exception). A newly bundled agent must be in the catalog, with its exception removed, before the first stable release shipping it. |
| libghostty-vt | Every patch in `vendor/libghostty-vt.patches.md` still applies and is indexed; `just check` maintenance tests cover this. |

For a diff-based view, run `git diff <last-tag>..HEAD --stat` on `src/protocol/`, `src/api/schema/`, `tests/fixtures/`, `distribution/`, `src/integration/` and `vendor/`, and use the `wire-compat-reviewer` agent on protocol/API changes.

## Step 3 — Performance gate (stable releases)

Before a **stable** release: `just bench-release-smoke` must compare the candidate with the current stable binary under hidden and visible output.

- If the result moves materially, or when validating performance work, repeat with `TERMLM_PERF_SAMPLE_SECONDS=60` and investigate the affected scenario.
- For changes that widen render/layout/detection work, also run `just bench-render-scale` (1 vs 15+ panes) and report the scaling delta.

Benchmarks are supporting evidence, not a substitute for behavioral tests.

## Step 4 — Version and artifacts

1. Bump `version` in `Cargo.toml` (and refresh `Cargo.lock` with a build) in a `chore: release vX.Y.Z` commit — via the `commit` skill, with confirmation.
2. Build candidate artifacts if needed: `gh workflow run build-artifacts-manual.yml -f build_group=<linux|macos|windows|all>` (confirm first), then watch with `gh run list --workflow build-artifacts-manual.yml --limit 1`.
3. Tag only after the user confirms: annotated `vX.Y.Z` tag. Do not push the tag until asked.

## Step 5 — Hand-off

Summarize: version, channel, checks run and results, contract items touched, and everything **not** verified (publishing, update-manifest generation, installer smoke tests on each OS). Ask the user how and where the artifacts and manifests get published.
