# ADR 0001 — Record architecture decisions

Date: 2026-06-08
Status: Accepted

## Context

We need a lightweight, durable record of significant architectural decisions so future maintainers (including future-us) understand **why** the system looks the way it does.

## Decision

We use **Architecture Decision Records** in the Michael Nygard format, stored under `docs/adr/`, numbered sequentially. Each ADR captures one decision, its context, and its consequences.

## Consequences

- Decisions are reviewed in PRs alongside code.
- New joiners can read the ADR set to understand the system.
- Superseded decisions stay in the repo with a `Superseded by` pointer; they are not deleted.

## Alternatives considered

- **No ADRs** — easy now, expensive in 6 months.
- **Confluence / Notion** — drifts from the code; not reviewed in PRs.
