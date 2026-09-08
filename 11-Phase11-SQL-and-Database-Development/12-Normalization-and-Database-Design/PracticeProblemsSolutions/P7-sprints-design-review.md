# P7 — Full Design Review: Adding "Sprints" to TaskFlow

See [Practice-Problems.md](../Practice-Problems.md) P7 for the full requirement list. This is the
modelling/normalization companion to Topic 11's P8 (which hardens the same feature with
constraints) — complete both for the full picture.

## TODO: your design review here

1. **Normalized table design** (`app.Sprints`, `app.SprintTasks`) — real column lists, and a
   form-by-form (1NF/2NF/3NF) justification for why the design doesn't violate any of them.

2. **One deliberate denormalization** (e.g. a cached committed-points total) — name the exact
   mechanism (trigger / indexed view / scheduled job) that keeps it correct.

3. **Mermaid `erDiagram`** sketch of how `Sprints` fits into the existing schema (reference
   [P4-er-diagram.md](./P4-er-diagram.md)).

```mermaid
erDiagram
    %% TODO: Sprints, SprintTasks, and their relationships to Teams and Tasks.
```

4. **Multi-tenancy retrofit** — which model (§14 in Notes.md) would you choose for this feature
   plus the existing schema, and what is the single highest-risk mistake in that model?

5. **Reporting warehouse sketch** — describe a `FactSprintProgress` row (grain, key dimensions)
   for a burndown-chart warehouse built on this feature.
