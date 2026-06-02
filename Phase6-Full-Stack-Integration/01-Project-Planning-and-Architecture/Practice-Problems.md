# Topic 1: Project Planning & Architecture — Practice Problems

> Six artifacts you author with a markdown editor, not a compiler. Each one is a real piece of the **TaskFlow** project's `docs/` folder.

**Concept tags:** `personas` `user-stories` `gherkin` `moscow` `c4` `mermaid` `adr` `openapi` `stride`

**Setup:** Create a working folder `Phase6-Practice/01/`. Drop your answers as markdown files there.

---

## P1 — User Stories with Acceptance Criteria  *(Easy)*

**Tags:** `requirements` `user-stories` `gherkin`

### Requirements

- Produce **10 user stories** for TaskFlow MVP using Connextra format.
- Cover at least 3 personas (Member, PM, Admin).
- For each story write **at least 2 acceptance criteria** in Given / When / Then.

### Deliverable

`P1-user-stories.md` containing a table of stories + a section per story with its scenarios.

### Hints

- Vertical slices only (UI + API + DB), not technical tasks.
- Avoid "the system shall…" — keep the user voice.
- Acceptance criteria must be **testable** (specific status codes, fields, side effects).

### Look-fors (rubric)

- [ ] All 10 stories have a clear persona, capability, value.
- [ ] At least 3 personas represented.
- [ ] Acceptance criteria reference observable outcomes (HTTP, UI, DB).
- [ ] At least 2 negative-path scenarios (e.g. unauthorized, validation fails).

---

## P2 — MoSCoW Prioritization & MVP Scope Statement  *(Easy)*

**Tags:** `prioritization` `moscow` `scope`

### Requirements

- Take the 10 stories from P1 plus 5 extra "nice-to-have" ideas you invent.
- Place each into Must / Should / Could / Won't (this release) with a 1-sentence justification.
- Write a **one-paragraph MVP scope statement** (≤ 80 words) that someone unfamiliar with the project can read in 30 seconds.

### Deliverable

`P2-moscow.md` with two sections: the table and the scope paragraph.

### Hints

- "Must" items are usually < 30% of the backlog. If yours is 80% Must, you're not prioritizing — re-read NFRs and ask "what breaks if we don't ship this?".
- The scope statement should fit on one Slack message.

### Look-fors

- [ ] Buckets are roughly balanced (Must ≤ 40%).
- [ ] Justifications reference user value or NFR.
- [ ] Scope paragraph mentions: who, what, the key constraints (auth, hosting), what's *out*.

---

## P3 — C4 System Context + Container Diagrams  *(Medium)*

**Tags:** `c4` `architecture` `mermaid`

### Requirements

Draw the **C1 (System Context)** and **C2 (Container)** diagrams for TaskFlow using mermaid in a markdown file.

C1 must include:
- Three external user types.
- Three external systems (email, storage, optional IdP).

C2 must include:
- Web SPA, API container, SignalR (note if same process or separate), SQL DB, Redis, Blob, plus any background-jobs container you plan.
- Protocol on every arrow (HTTPS / WSS / TCP).

Add a 200-word **architecture narrative** explaining why each container exists.

### Deliverable

`P3-c4-diagrams.md` with the two mermaid blocks + narrative.

### Hints

- Don't draw classes / database tables — that's C4 level 4.
- An "external system" you don't control should look different from one you own (use shape/styling).

### Look-fors

- [ ] No internal components leak into C1.
- [ ] All arrows have a protocol label.
- [ ] Narrative justifies why each container is its own deployable unit (or isn't).

---

## P4 — Architecture Decision Records  *(Medium)*

**Tags:** `adr` `documentation`

### Requirements

Author **3 ADRs** as separate files in `P4-adrs/`:

1. `ADR-0001-database-engine.md`
2. `ADR-0002-auth-strategy.md`
3. `ADR-0003-frontend-framework.md`

Each must use this template:

```
# ADR-NNNN: <Title>
- **Status:** Proposed | Accepted | Superseded by ADR-XXXX
- **Date:** YYYY-MM-DD
- **Deciders:** <names / personas>

## Context
...
## Decision
...
## Consequences
- (+)
- (-)
## Alternatives considered
- <Option> — rejected because ...
```

### Deliverable

3 markdown files matching the template.

### Hints

- ADRs are **short** (≤ 1 page).
- Be honest about the negatives — that's how ADRs earn trust.
- Link to evidence (benchmarks, blog posts, prior incidents) where possible.

### Look-fors

- [ ] Status, date, deciders filled in.
- [ ] At least 2 alternatives per ADR with rejection reasons.
- [ ] Consequences include both upsides and downsides.

---

## P5 — OpenAPI Contract for `/projects` and `/tasks`  *(Hard)*

**Tags:** `openapi` `rest` `contracts`

### Requirements

Write `P5-openapi.yaml` (OpenAPI 3.1) covering:

- `/api/v1/projects` — `GET` (list with pagination), `POST` (create)
- `/api/v1/projects/{projectId}` — `GET`, `PUT`, `DELETE`
- `/api/v1/projects/{projectId}/tasks` — `GET`, `POST`
- `/api/v1/tasks/{taskId}` — `GET`, `PUT`, `PATCH`, `DELETE`

Schemas required:
- `Project`, `ProjectCreate`, `ProjectUpdate`
- `Task`, `TaskCreate`, `TaskUpdate`, `TaskPatch` (JSON Patch)
- `PageOfTasks` (envelope: items, page, pageSize, total)
- `ProblemDetails` (RFC 7807) and `ValidationProblemDetails`

Include:
- `securitySchemes: bearerAuth` with `type: http`, `scheme: bearer`, `bearerFormat: JWT`.
- All operations require `bearerAuth` except where noted.
- Response codes: 200, 201, 204, 400, 401, 403, 404, 409, 412, 422.
- At least one example body per schema.

### Hints

- Validate with the [Swagger Editor](https://editor.swagger.io/) or `redocly lint`.
- Use `oneOf` to model the difference between `ProblemDetails` and `ValidationProblemDetails`.
- For PATCH, content-type is `application/json-patch+json` and body is an array of operations.

### Look-fors

- [ ] File parses cleanly (no warnings).
- [ ] Pagination and sort query parameters defined as reusable parameters.
- [ ] Security applied globally with per-operation override where needed.
- [ ] Errors model uses RFC 7807 with `traceId` extension.

---

## P6 — STRIDE Threat Model: Auth + File Upload  *(Hard)*

**Tags:** `security` `stride` `threat-modeling`

### Requirements

Threat-model two flows and produce mitigations.

**Flow A — Login + token refresh**
1. Browser POSTs `email + password` to `/auth/login`.
2. API returns `{ accessToken, refreshToken }`.
3. Browser stores access token in memory, refresh token in HttpOnly cookie.
4. On 401, browser POSTs `/auth/refresh` to get new access token.

**Flow B — Direct-to-blob file upload**
1. Web requests `POST /attachments/upload-url` for a task.
2. API returns a **SAS URL** for Azure Blob (write-only, 5 min expiry).
3. Browser PUTs file directly to blob.
4. Browser POSTs `/attachments` with blob path; API records metadata + virus-scan job.

For each flow:
- List **at least 2 threats per STRIDE letter** (Spoofing, Tampering, Repudiation, Info Disclosure, DoS, Elevation).
- Note likelihood (L/M/H), impact (L/M/H), and mitigation (control or process).
- Highlight the top 3 risks you'd address first.

### Deliverable

`P6-threat-model.md` with one table per flow + a "Top 3" callout.

### Hints

- Don't list generic threats — be specific to the flow ("attacker captures refresh token from XSS payload" beats "attacker steals token").
- Mitigations should map to controls you can verify in a test or config.
- Some threats apply across flows — record them once and reference.

### Look-fors

- [ ] At least 12 threats per flow (≥ 2 per STRIDE letter).
- [ ] Likelihood + impact + mitigation columns filled in.
- [ ] Mitigations reference concrete tech (HttpOnly cookie, SAS expiry, rate limiter, content-type allow-list).
- [ ] Top 3 risks justified.

---

## Self-Review Checklist

Before declaring Topic 1 done, confirm:

- [ ] You can name the four C4 levels and which two you produced.
- [ ] You can write a story + Gherkin scenario from memory.
- [ ] You can list MoSCoW buckets and explain when "Won't" matters.
- [ ] You wrote 3 ADRs and can defend each decision out loud.
- [ ] Your OpenAPI lints clean.
- [ ] You identified at least 12 threats per flow with mitigations.
- [ ] You committed `docs/architecture/` to your TaskFlow repo.
