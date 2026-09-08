/*=============================================================================
  Topic 03 — SELECT, Filtering & Sorting
  P6 — Two Pagination Engines                                         (Hard)
  -----------------------------------------------------------------------------
  Tags: offset-fetch, keyset-pagination, determinism, indexes, api-design

  PROBLEM
  GET /api/tasks?page=...&pageSize=... currently uses OFFSET ... FETCH. It is
  fine at 35 rows and unusable at 5 million. Build and compare both engines.

  REQUIREMENTS
    1. OFFSET engine. Parameterise @PageNumber and @PageSize. Order by
       CreatedAtUtc DESC with a unique tiebreaker. Return page 1 and page 2.
    2. Demonstrate the NON-DETERMINISM of a missing tiebreaker: order only by
       PriorityId with @PageSize = 5, fetch page 1 and page 2, and explain why
       a row could legitimately appear on both.
    3. KEYSET engine. Same ordering, driven by @LastCreatedAtUtc / @LastTaskId.
       Return page 1 (no parameters) and the next page (parameters taken from
       page 1's last row).
    4. Write the keyset predicate BOTH ways — the plain OR form and the
       >= + parenthesised-OR rewrite — and comment on why the second seeks better.
    5. Note that T-SQL has no row-value comparison (a, b) > (@a, @b), and show
       what the PostgreSQL/MySQL version would look like.
    6. Create a supporting index on the exact sort key, capture SET STATISTICS IO
       logical reads for both engines, then DROP the index. Record the numbers.
    7. Build a comparison table in comments covering: cost of page N, arbitrary
       page jump, total-count availability, stability under concurrent inserts,
       and index requirements.
    8. Recommend which engine TaskFlow should use for (a) the admin grid with
       page numbers and (b) the mobile infinite-scroll feed. Justify each.

  HINTS
    - OFFSET requires ORDER BY; FETCH requires OFFSET; TOP cannot be combined
      with OFFSET...FETCH in the same query expression.
    - The index you want is ON app.Tasks (CreatedAtUtc, TaskId) — or
      (CreatedAtUtc DESC, TaskId DESC) to match a descending sort exactly.
    - Cursor tokens sent to a client should be opaque (base64) so callers
      cannot forge them into a data-leak vector.
    - 35 rows will not show a performance difference. Reason about PLAN SHAPE
      and asymptotics, not milliseconds.

  CLEANUP: this script MUST drop every index it creates.
=============================================================================*/

USE TaskFlowDb;
GO

SET STATISTICS IO ON;
GO

-----------------------------------------------------------------------------
-- 1. OFFSET engine — parameterised, deterministic. Page 1 and page 2.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 2. Non-determinism demo: ORDER BY PriorityId only, @PageSize = 5.
--    Show pages 1 and 2 and explain how a row can appear on both.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 3. Keyset engine — page 1 (no cursor), then the next page (cursor supplied)
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 4. Both keyset predicate forms, side by side.
--    Why does the >= + parenthesised-OR rewrite seek better?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 5. Row-value comparison: not valid in T-SQL.
--    Show the PostgreSQL / MySQL equivalent in a comment.
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- 6. Supporting index + logical reads for both engines. Record the numbers.
--    CREATE the index, measure, then DROP it.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 7. Comparison table (comment block): cost of page N, arbitrary page jump,
--    total-count availability, stability under inserts, index requirements.
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- 8. Recommendation for (a) admin grid and (b) mobile infinite scroll.
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- CLEANUP — leave TaskFlowDb exactly as you found it
-----------------------------------------------------------------------------
DROP INDEX IF EXISTS IX_Tasks_Created_TaskId ON app.Tasks;
GO

SET STATISTICS IO OFF;
GO
