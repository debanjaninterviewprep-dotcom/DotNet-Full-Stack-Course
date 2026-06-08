---
mode: agent
description: Bump TaskFlow API contract version end-to-end (OpenAPI, server, client, ADR).
---

Bump the TaskFlow API contract from `${input:fromVersion}` to `${input:toVersion}`.

Steps:
1. Update `backend/src/TaskFlow.Api` to register the new version alongside the old one; do not remove the old route yet.
2. Update the OpenAPI spec; regenerate examples; ensure all responses include `traceId`.
3. Regenerate the Angular client under `frontend/src/app/core/api/`.
4. Add an ADR `docs/adr/NNNN-api-version-${input:toVersion}.md` capturing the change, deprecation date, and migration notes.
5. Update `docs/runbook.md` with the rollback steps.
6. List all PR review checks the reviewer should perform.

Do NOT change behaviour of the old version. Confirm at the end which files were changed.
