# P6 — Design Decision: JSON Column vs Real Columns vs Temporal History

See [Practice-Problems.md](../Practice-Problems.md) P6 for the full requirement list.

## TODO: your recommendations here

### 1. `customer_escalation_ticket_id` (~2% of tasks, format varies by customer, never filtered/joined)

- **Recommendation:**
- **Justification:**

### 2. Full history of `StoryPoints` changes, for velocity-estimation audits

- **Recommendation:**
- **Mechanism chosen (trigger-based audit / `OUTPUT`-based audit / temporal table) and why:**
- **Whole-row temporal versioning vs a column-specific audit trigger — which fits better here, and why:**

### 3. `compliance_flags` (small closed vocabulary, <= 5 values, filtered in almost every compliance dashboard query)

- **Recommendation:**
- **Justification (contrast explicitly with #1):**
