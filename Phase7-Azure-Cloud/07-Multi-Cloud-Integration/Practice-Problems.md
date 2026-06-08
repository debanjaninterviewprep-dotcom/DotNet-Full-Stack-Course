# Topic 7: Multi-Cloud Integration — Practice Problems

> Mostly **design** exercises. Multi-cloud is more architecture-and-tradeoffs than code; you'll produce diagrams and policy artifacts. One small code exercise simulates an OIDC token exchange.

**Concept tags:** `multi-cloud` `oidc-federation` `egress-cost` `architecture` `terraform` `opentelemetry`

**Setup:** No new Azure resources required. AWS or GCP free-tier accounts are optional but useful. Diagrams in Mermaid.

---

## P1 — Multi-Cloud Decision Matrix  *(Easy)*

**Tags:** `architecture` `decision-record`

### Requirements

For TaskFlow, evaluate **three** real services that *might* belong in another cloud:
1. Document OCR / AI extraction (e.g. AWS Textract).
2. ML model serving (e.g. GCP Vertex AI).
3. CDN at scale (e.g. CloudFront vs Azure Front Door).

For each, fill out a **decision matrix** with:
- Equivalent in Azure (if any).
- Reason to choose other-cloud (if any).
- Estimated egress cost at 100 GB / month.
- Identity model (federation? long-lived?).
- Operational cost (extra runbooks, monitoring tools).

Recommend a final placement and write a 2-paragraph **ADR**.

### Deliverable

`P1-decision.md` (matrix + ADR).

### Look-fors

- [ ] Each row has a quantified egress cost, not "depends".
- [ ] Identity model explicit (OIDC vs API key).
- [ ] Final recommendation defended with at least one quantitative argument.

---

## P2 — C4 Diagram for a Cross-Cloud TaskFlow  *(Medium)*

**Tags:** `c4` `mermaid` `architecture`

### Requirements

Author a **C4 Container diagram** showing TaskFlow + two external-cloud integrations:
- AWS Textract (synchronous OCR).
- GCP Vertex AI (async ML enrichment via Service Bus → relay → SQS → Lambda).

Annotate every cross-cloud arrow with:
- Protocol (HTTPS, AMQP, etc.).
- Auth (OIDC token, signed URL, etc.).
- Expected throughput (msgs/min or req/s).

Add a **threat model paragraph** identifying the 3 biggest risks and mitigations.

### Deliverable

`P2-c4-cross-cloud.md`.

### Look-fors

- [ ] All cross-cloud arrows specify auth.
- [ ] No long-lived static credentials in the design.
- [ ] Threats include data exfil, token theft, egress DDoS-of-our-wallet.

---

## P3 — OIDC Federation Walkthrough (Azure ↔ AWS)  *(Medium)*

**Tags:** `oidc` `federation` `iam`

### Requirements

Document the **end-to-end setup** for:
- TaskFlow Function App → AWS S3 bucket using Workload Identity Federation.

Sections required:
1. Entra App Registration (or Managed Identity) representing the workload.
2. AWS IAM OIDC provider creation (issuer URL, thumbprint).
3. AWS IAM role with the federated trust policy.
4. .NET sample in `OidcFederation.Sample` that:
   - Acquires an Entra token for AWS audience.
   - Calls `AssumeRoleWithWebIdentity`.
   - Lists objects in an S3 bucket.

You don't need a real AWS account to *write* the doc; mark steps "[verified]" if you tested, "[planned]" otherwise.

### Deliverable

`P3-oidc/` folder: `walkthrough.md`, the trust policy JSON, and the C# sample.

### Look-fors

- [ ] No static AWS access keys anywhere.
- [ ] Trust policy uses both `aud` and `sub` conditions.
- [ ] Code uses short-lived credentials (`DurationSeconds`).

---

## P4 — Egress Cost Estimator  *(Medium)*

**Tags:** `cost` `egress`

### Requirements

Write a small spreadsheet (CSV or Markdown table) modelling **annual egress** for three TaskFlow scenarios:
1. 100 GB/day Azure → AWS Textract.
2. 5 GB/day Azure → GCP Vertex AI.
3. 50 GB/day Azure → external CDN.

For each: per-cloud egress price, total monthly, total annual. Include the assumption that 30% can be batched/compressed and re-estimate.

Add a **conclusion** paragraph recommending which scenarios pass a "5% of revenue" sniff test.

### Deliverable

`P4-egress-costs.md`.

### Look-fors

- [ ] Sources cited for prices (link to AWS/Azure pricing pages, dated).
- [ ] Compression assumption stated.
- [ ] Sensible recommendation.

---

## P5 — Cross-Cloud Service Bus → SQS Relay  *(Hard, design)*

**Tags:** `messaging` `relay` `at-least-once`

### Requirements

Design (no full code) a relay Function App that:
- Triggers on `tasks-events` topic, subscription `cross-cloud-relay`.
- Forwards every message to AWS SQS using OIDC federation.
- Handles partial failures (SB ack only after SQS success).
- Detects and skips duplicates using a Redis idempotency cache.

Include:
- Sequence diagram in Mermaid.
- Error/retry plan (SB retry → SQS DLQ-equivalent).
- Failure scenarios + how the system recovers.

### Deliverable

`P5-relay-design.md`.

### Look-fors

- [ ] Idempotency design (key, TTL).
- [ ] Failure modes covered (SQS down, network blip, transient throttle).
- [ ] Cost section: egress + SB + SQS + Redis estimate at 1k msg/s.

---

## Submission Checklist

- [ ] Diagrams render (Mermaid in GitHub markdown).
- [ ] Cost numbers grounded in cited sources.
- [ ] No long-lived cross-cloud credentials in any artifact.

---

## Stretch Goals

- Implement P5 for real against an AWS SQS sandbox.
- Add **OpenTelemetry traces** that span Azure → AWS so you can see end-to-end latency in App Insights.
- Compare a Terraform module that provisions both Azure & AWS ends to a Bicep+CFN combo.
