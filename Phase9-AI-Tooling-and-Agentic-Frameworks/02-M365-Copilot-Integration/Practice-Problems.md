# Practice Problems — M365 Copilot Integration

> Tell me **"check"** after finishing for grading.

---

## P1 — Build a TaskFlow Declarative Agent

**Goal:** Ship a no-code-action declarative agent that helps a team explore TaskFlow knowledge curated in SharePoint.

**Tasks:**
1. Scaffold with the Microsoft 365 Agents Toolkit (`atk new`).
2. Author `declarativeAgent.json`: name, description, instructions, 5 conversation starters, knowledge capability pointing at a SharePoint document library.
3. Provide a `manifest.json` for Teams app packaging.
4. Sideload to your tenant or M365 sandbox.

**Deliverable:** zipped `appPackage/` + a screenshot of the agent answering a question with a citation.

**Look-fors:** Instructions enforce tone + cite-required behaviour; conversation starters are useful; knowledge source actually grounds answers.

---

## P2 — Add a Read-Only API Plugin

**Goal:** Extend P1's agent with an action that calls a real TaskFlow API.

**Tasks:**
1. Author `taskflow-openapi.yaml` with at least 3 operations: `getOverdueTasks`, `getProjectById`, `listProjects` (with pagination + status filter).
2. Author `taskflow-api-plugin.json` referencing the OpenAPI doc, with Entra OAuth (`TaskFlow.Read`).
3. Wire it into the declarative agent via `actions`.
4. Provision Entra app registration, scope, and admin consent.

**Deliverable:** All three files + a screenshot of Copilot Chat invoking `getOverdueTasks`.

**Look-fors:** OpenAPI operations have rich descriptions; auth is delegated OAuth; pagination clearly modelled.

---

## P3 — Add a Write Operation with Confirmation

**Goal:** Add `updateTaskStatus` requiring user confirmation before execution.

**Tasks:**
1. Add the PATCH operation to OpenAPI with explicit `description_for_model` warning.
2. In the plugin manifest, enable an Adaptive-Card confirmation for the operation.
3. Test: ask Copilot "Mark TF-2031-task-7 as done." — confirm card appears, then approve.
4. Capture the screenshot.

**Deliverable:** Updated OpenAPI + plugin + screenshot. Brief writeup of what the confirmation card actually showed.

**Look-fors:** Confirmation triggered; task was not updated until approved; failure case (deny) tested.

---

## P4 — Graph Connector for TaskFlow Projects

**Goal:** Push TaskFlow projects into the semantic index so they appear as citations in M365 Copilot answers.

**Tasks:**
1. Console app in C# using `Microsoft.Graph`.
2. Register an external connection `taskflow-projects`.
3. Define a schema with `title`, `status`, `owner`, `updatedDate`.
4. Push 20 sample projects with ACLs scoped to a real Entra group.
5. Verify items appear in Microsoft Search results for an authorised user and **do not** appear for an unauthorised one.

**Deliverable:** Working source + screenshots of both authorised and unauthorised search experiences.

**Look-fors:** ACLs honoured; schema marks the right fields searchable/retrievable; idempotent push (re-run doesn't duplicate).

---

## P5 — Plugin Decomposition

**Goal:** Show you understand why one mega-plugin is worse than three focused plugins.

**Tasks:**
1. Take a 25-operation TaskFlow OpenAPI doc (mock or real).
2. Decompose into 3 plugins by capability: read, write, admin.
3. Justify the split in a `decomposition.md` document — what factor drove each boundary (auth scope, frequency of use, write risk, audience).
4. Show how each plugin is referenced from the declarative agent.

**Deliverable:** Three plugin manifests + `decomposition.md` + agent manifest.

**Look-fors:** Operation count per plugin reasonable (≤ ~12); auth scopes match operation risk; rationale is non-obvious in at least one case.

---

## P6 — Governance Checklist

**Goal:** Build a pre-rollout checklist that prevents your plugin from getting blocked by a tenant admin.

**Tasks:** Author `governance-checklist.md` covering at minimum:
- Identity / auth (delegated only; Entra scopes documented).
- Data residency (where API runs, what data flows).
- Logging / audit (Purview hooks; per-call correlation).
- DLP / sensitivity label handling.
- Rollback / disable plan.
- User comms plan + 2-week pilot definition.

**Deliverable:** The checklist + a 1-page rollout plan.

**Look-fors:** Realistic for a regulated environment; explicit on logs + on opt-out.

---

## P7 — When Declarative is Not Enough

**Goal:** Identify a TaskFlow scenario that requires a **custom engine agent**, justify it, and sketch the architecture.

**Tasks:**
1. Pick a scenario (e.g., "Weekly portfolio risk briefing that pulls from TaskFlow + Jira + GitHub and writes a Loop page").
2. Explain why declarative + plugins don't fit (orchestration steps, multi-source aggregation, custom tools).
3. Architecture diagram: Bot Framework + Semantic Kernel + plugin tools + state store.
4. Cost & governance compared with declarative.

**Deliverable:** `custom-engine-design.md` with diagram (Mermaid).

**Look-fors:** Reason is real, not invented; diagram shows clear boundaries; cost estimate honest.

---

## Scoring Rubric

| # | Pts | Full marks |
|---|---|---|
| P1 | 10 | Agent runs; citations appear |
| P2 | 15 | OpenAPI quality high; OAuth wired |
| P3 | 15 | Confirmation actually gates the write |
| P4 | 20 | ACL trimming verified both ways |
| P5 | 15 | Decomposition rationale defensible |
| P6 | 10 | Realistic checklist |
| P7 | 15 | Justified, not over-engineered |

Total: 100. Pass: 70.
