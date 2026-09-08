/*=============================================================================
  Topic 04 — Built-In Functions & Expressions
  P6 — The SLA Dashboard Expression Engine                            (Hard)
  -----------------------------------------------------------------------------
  Tags: case, iif, choose, greatest-least, concat-ws, string-agg, format,
        determinism

  PROBLEM
  Build the single query behind TaskFlow's SLA dashboard: one row per
  NON-TERMINAL task, with these computed columns.

    | Column          | Definition                                                        |
    |-----------------|-------------------------------------------------------------------|
    | TaskRef         | ProjectCode + '-' + zero-padded TaskId (6 digits)                 |
    | Headline        | Primary assignee FullName, JobTitle and CountryCode, joined so a  |
    |                 | missing component leaves NO orphan separator                      |
    | SlaDeadlineUtc  | CreatedAtUtc + ref.Priorities.SlaHours; NULL when there is no SLA  |
    | SlaState        | 'No SLA' / 'Breached' / 'At risk' (<25% of window left) / 'On track'|
    | LastTouchedUtc  | Latest non-NULL of CreatedAtUtc, ModifiedAtUtc, CompletedAtUtc     |
    | Labels          | Comma-separated LabelName ordered by LabelId; '(none)' if no labels|

  THEN
    1. Write SlaState twice — searched CASE and nested IIF. State which you would
       ship and why.
    2. Write LastTouchedUtc twice — GREATEST (2022+) and the
       CROSS APPLY (VALUES ...) + MAX fallback. Confirm both agree.
    3. Add a PriorityLabel column using CHOOSE, then argue why
       ref.Priorities.PriorityName is the better source.
    4. Demonstrate that a SIMPLE CASE cannot match NULL, using ModifiedAtUtc.
    5. Add a DueDateDisplay column with FORMAT, then the CONVERT-with-style-code
       equivalent. State the performance and determinism consequences of each.
    6. List every non-deterministic function used anywhere in your query and state
       which of them would prevent this query becoming an indexed view.

  HINTS
    - Primary assignee: app.TaskAssignments WHERE IsPrimary = 1. Not every task
      has one — your join must not drop rows.
    - ref.Priorities.SlaHours is NULL for PriorityCode = 'NONE'.
    - STRING_AGG needs CAST(... AS NVARCHAR(MAX)) on the INPUT or you risk
      Msg 9829, and WITHIN GROUP (ORDER BY ...) for a deterministic order.
    - CHOOSE is 1-based and returns NULL out of range.
    - app.Tasks.ModifiedAtUtc is NULL for every seeded row — ideal for req 4.
=============================================================================*/

USE TaskFlowDb;
GO

-----------------------------------------------------------------------------
-- MAIN — the SLA dashboard query (searched CASE version)
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 1. SlaState written with nested IIF. Which do you ship, and why?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 2. LastTouchedUtc: GREATEST vs the CROSS APPLY (VALUES ...) + MAX fallback.
--    Confirm both agree.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 3. PriorityLabel via CHOOSE.
--    Why is ref.Priorities.PriorityName the better source?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 4. A simple CASE cannot match NULL — demonstrate with ModifiedAtUtc
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 5. DueDateDisplay: FORMAT vs CONVERT with a style code.
--    Performance and determinism consequences of each.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 6. Inventory of non-deterministic functions used above.
--    Which of them block turning this into an indexed view?
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)
GO
