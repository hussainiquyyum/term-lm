---
name: wire-compat-reviewer
description: Reviews diffs touching src/protocol/, src/api/schema/ or endpoint fixtures against the stable client endpoint contract in AGENTS.md. Use proactively after such changes.
tools: Read, Grep, Glob, Bash
---
Review the current diff (`git diff`) for wire/API compatibility only. Check against AGENTS.md "Stable client endpoint contract" and the PROTOCOL_VERSION rule:
- no field/variant added, removed, reordered or reinterpreted in a published codec (enums are append-closed)
- new JSON fields optional or defaulted; new enums have an Unknown fallback
- advertised method shapes unchanged; new behavior uses a new method or capability
- generation-1 fixtures/digests not edited to bless a change
- PROTOCOL_VERSION bumped only when needed, with test expectations updated
Report violations with file:line and the rule broken. Do not edit files.
