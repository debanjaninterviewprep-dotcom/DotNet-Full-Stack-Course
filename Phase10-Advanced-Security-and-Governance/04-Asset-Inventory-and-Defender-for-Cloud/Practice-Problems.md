# Practice Problems — Azure Asset Inventory & Defender for Cloud

> Tell me **"check"** after finishing.

---

## P1 — Inventory & Tag Hygiene Report

**Goal:** Build a one-page (Workbook or markdown) inventory report.

**Tasks:** Author 6 ARG queries:
1. Resources per type per subscription.
2. Resources created in the last 30 days.
3. Resources without `owner` tag.
4. Resources without `costCenter` tag.
5. Public IPs by subscription.
6. Storage accounts allowing public blob access.

Then build a Workbook (JSON or screenshots) showing them parameterised by subscription.

**Deliverable:** `inventory.kql` + `workbook.json` (or screenshots).

**Look-fors:** Queries are correct ARG (not pure KQL on logs); workbook parameters work.

---

## P2 — Tag Drift Remediation

**Goal:** Find the worst-tagged subscription and fix it.

**Tasks:**
1. Run the tag-drift KQL across all subs.
2. Pick the worst.
3. For each untagged resource: assign default `owner = unknown`, `costCenter = TBD`, then file a ticket per owner inferred from `createdBy`.
4. After 30 days, escalate any still untagged via a follow-up.

**Deliverable:** `tag-drift-report.md` + remediation script + ticketing CSV.

**Look-fors:** Script idempotent; ticket details actionable.

---

## P3 — Enable Defender Plans via IaC

**Goal:** Stand up MDC for TaskFlow.

**Tasks:**
1. Terraform module `mdc-baseline` that:
   - Enables Defender CSPM (Standard) on prod and non-prod subs.
   - Enables Defender for Storage, SQL, App Service on prod sub only.
   - Configures auto-provisioning, workspace, and security contact.
2. Apply.
3. Capture initial Secure Score per subscription.

**Deliverable:** Terraform module + before/after Secure Score screenshots.

**Look-fors:** Variables for selecting plans per env; outputs include current Secure Score.

---

## P4 — Governance Rule with Tag-Based Ownership

**Goal:** Auto-assign findings to owners.

**Tasks:**
1. Create a Defender CSPM **governance rule**:
   - Scope: prod subscription.
   - Condition: severity in (High, Medium).
   - Owner: tag `owner`.
   - Due date: High → 7 days, Medium → 30 days.
   - Notifications on assign and 1 day before due.
2. Trigger a finding (e.g., enable a storage account with public access in a sandbox).
3. Verify the assignment + email.

**Deliverable:** Rule export (JSON) + screenshots of assigned finding.

**Look-fors:** Owner derived from tag; SLAs match severity; notifications fire.

---

## P5 — Routing High Alerts to Teams

**Goal:** Send Defender high alerts to a Teams channel via Logic App.

**Tasks:**
1. Logic App workflow (consumption): trigger = HTTP webhook; action = post Adaptive Card to Teams.
2. Defender continuous export → Logic App on alerts where severity = High.
3. Trigger a simulated alert (e.g., enable Defender for Storage and upload a EICAR test file).
4. Capture the Teams message.

**Deliverable:** Logic App ARM/Terraform + Defender automation rule + screenshot of Teams card.

**Look-fors:** Card includes severity, entity, link to portal; deduplication or rate limit considered.

---

## P6 — Routing by Owner KQL

**Goal:** Build the "open recommendations by owner" query.

**Tasks:**
1. KQL joining `SecurityResources` recommendations with `Resources` (tag.owner).
2. Pivot: rows = owner, columns = severity, values = count.
3. Schedule it as a daily LA query, email a CSV to each owner.

**Deliverable:** Query + scheduled query rule (Terraform) + sample CSV output.

**Look-fors:** Join correct; query parameterisable by sub; per-owner CSV not whole-tenant blast.

---

## P7 — Monthly Inventory & Posture Report

**Goal:** Produce a one-pager (PDF/HTML) for steering meeting.

**Tasks:** Build the report covering:
- Inventory delta from last month.
- Tag hygiene %.
- Secure Score trend.
- Top 5 open recommendations by impact.
- Active high alerts.
- Top 3 attack paths.
- Compliance % (CIS or ASB).
- One "quick win" — a remediation that drops cost and risk.

**Deliverable:** Workbook JSON + exported PDF.

**Look-fors:** Numbers reconcile across sections; quick-win is concrete.

---

## Scoring Rubric

| # | Pts | Full marks |
|---|---|---|
| P1 | 15 | Queries correct; workbook parameters work |
| P2 | 10 | Idempotent; ticketing actionable |
| P3 | 15 | Plans correct; Secure Score captured |
| P4 | 15 | Rule works; tag drives owner |
| P5 | 15 | Card meaningful; dedup considered |
| P6 | 15 | Pivot correct; per-owner email |
| P7 | 15 | Numbers reconcile; quick-win identified |

Total: 100. Pass: 70.
