# Practice Problems — Multi-Account Governance

> Tell me **"check"** after finishing.

---

## P1 — Tenant Landing-Zone Design

**Goal:** Author the design doc for TaskFlow's tenant.

**Tasks:** In `landing-zone-design.md`:
1. MG hierarchy diagram (Mermaid).
2. Subscription list with naming convention + purpose.
3. Region strategy (primary, secondary, failover plan).
4. Network topology (hub-spoke or vWAN) + justification.
5. Identity model summary (groups, PIM).
6. Central logging & SIEM choice.
7. FinOps model: budgets per MG/sub, chargeback approach.
8. Operating-model RACI: Platform / SecOps / FinOps / App teams.

**Deliverable:** `landing-zone-design.md` (~3 pages).

**Look-fors:** CAF-aligned, realistic for your scale, justified per choice.

---

## P2 — Subscription-Vending Pipeline

**Goal:** Build a pipeline that issues a new landing-zone subscription from a PR.

**Tasks:**
1. PR form: YAML or JSON file under `requests/<team>-<env>.yaml` with: team, env, cost centre, region, connectivity, data class.
2. CI workflow: validates form, runs Terraform module `subscription`, peers spoke to hub, sets RBAC + budget, enables MDC, outputs sub ID + welcome notes.
3. OIDC, no secrets.
4. Demonstrate one end-to-end run for a sandbox sub.
5. Document the rollback procedure.

**Deliverable:** Module source + workflow + demo log + rollback notes.

**Look-fors:** Idempotent; review-gated; outputs actionable.

---

## P3 — Hub-Spoke Network

**Goal:** Stand up a hub-spoke topology in Terraform.

**Tasks:**
1. Hub VNet with subnets for Azure Firewall, Bastion, gateway, DNS resolver.
2. Two spokes peered to the hub.
3. Route tables forcing 0.0.0.0/0 from spokes → firewall.
4. Private DNS zone `privatelink.vaultcore.azure.net` linked from hub; both spokes resolve through hub.
5. Demonstrate a Key Vault private endpoint in spoke A resolves correctly from spoke B (cross-spoke transit via hub).

**Deliverable:** Terraform + a curl/nslookup transcript proving cross-spoke resolution.

**Look-fors:** No double-encryption / no transit allowed without firewall; DNS centralised.

---

## P4 — Central Logging Setup

**Goal:** All subs forward diagnostic logs to a central LAW.

**Tasks:**
1. Central LAW in Management sub, with daily cap, retention 90d hot + 1y archive.
2. DINE policy to auto-enable Diagnostic Settings forwarding all resource categories to the central LAW (use the built-in initiative).
3. Assign policy at Landing Zones MG; verify three resources auto-onboard.
4. Cross-workspace KQL: count requests across all envs.

**Deliverable:** LAW Terraform + policy assignment + verification screenshots + KQL.

**Look-fors:** Policy MI least-privilege; cross-workspace query works.

---

## P5 — Tag-Driven Chargeback

**Goal:** Build the FinOps loop.

**Tasks:**
1. Enforce `costCenter` tag (Topic 2 policy).
2. Configure **cost allocation rule** to redistribute Hub Firewall + central LAW cost by spoke traffic share (use Cost Management UI export or Terraform).
3. Schedule a daily export of Cost Management data → Storage.
4. Build a Power BI / Fabric report (or KQL Workbook) showing: cost by team / app / env this month vs last.
5. Configure budget alerts on the top 3 subscriptions.

**Deliverable:** Tag policy + allocation-rule export + report screenshot + budget config.

**Look-fors:** Allocation reflects reality; report drillable; alerts not just email-only.

---

## P6 — Azure Lighthouse Onboarding

**Goal:** Onboard a "customer" tenant for management from your tenant.

**Tasks:**
1. ARM template that grants `Reader` on a chosen sub + `Contributor` on a chosen RG to a group in your managing tenant.
2. Deploy to a test tenant (or simulate by re-using your own).
3. Confirm operators in managing tenant see the delegated scope.
4. PIM in the managing tenant for elevated privileges.

**Deliverable:** Template + screenshots + PIM config.

**Look-fors:** No standing elevated access; audit log in both tenants; documentation for offboarding.

---

## P7 — Drift & Hygiene Reports

**Goal:** Implement the five mandatory weekly reports.

**Tasks:** Build:
1. Sub inventory + owner.
2. Tag hygiene %.
3. Secure Score trend.
4. Cost vs budget.
5. Policy non-compliance summary.

For each: KQL or PowerShell + scheduled email or Teams post.

**Deliverable:** `reports/` directory + scheduled trigger config + sample outputs.

**Look-fors:** Idempotent; signal-rich; not "all green / no detail".

---

## Scoring Rubric

| # | Pts | Full marks |
|---|---|---|
| P1 | 15 | CAF-aligned; choices justified |
| P2 | 20 | Vending works end-to-end; review-gated |
| P3 | 15 | Network topology correct; transit verified |
| P4 | 15 | Policy MI least-privilege; cross-workspace works |
| P5 | 15 | Allocation realistic; alerts wired |
| P6 | 10 | Lighthouse onboarding works; PIM in managing tenant |
| P7 | 10 | Five reports actually scheduled and useful |

Total: 100. Pass: 70.
