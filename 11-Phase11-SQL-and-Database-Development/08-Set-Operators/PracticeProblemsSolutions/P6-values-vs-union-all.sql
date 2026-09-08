/*
    P6 -- VALUES Constructor vs UNION ALL of Literals  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. Inline priority-to-SLA lookup using UNION ALL of five single-row SELECTs
       (mirroring ref.Priorities, but as a literal, disconnected table).
    2. Same lookup rewritten as a single VALUES table constructor with a column alias list.
    3. Join each version to app.Tasks and confirm both versions produce identical output.
    4. Compare the two versions' plans -- which plan operator disappears in the VALUES version?
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
