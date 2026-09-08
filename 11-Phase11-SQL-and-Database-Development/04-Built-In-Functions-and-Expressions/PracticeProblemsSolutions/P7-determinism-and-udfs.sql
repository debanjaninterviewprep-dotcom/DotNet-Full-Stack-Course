/*=============================================================================
  Topic 04 — Built-In Functions & Expressions
  P7 — Determinism and the Scalar-Function Tax                        (Hard)
  -----------------------------------------------------------------------------
  Tags: determinism, computed-columns, persisted, scalar-udf, inline-tvf,
        udf-inlining, sargability, execution-plans

  REQUIREMENTS
    1. Query COLUMNPROPERTY(OBJECT_ID('app.Users'), 'FullName', 'IsDeterministic').
       Explain why app.Users.FullName qualifies for PERSISTED, and what would
       happen to the schema if its definition used FORMAT instead.
    2. Add a DETERMINISTIC persisted computed column CreatedYear to app.Tasks,
       index it, and show that  WHERE YEAR(t.CreatedAtUtc) = 2025  — written
       exactly like that, unchanged — can now use the index. Explain why the
       optimiser matches the expression.
    3. Attempt to add a NON-deterministic persisted computed column (e.g. one
       involving SYSUTCDATETIME() or FORMAT). Capture the error verbatim and
       explain it.
    4. Explain the difference between DETERMINISTIC and PRECISE, and why a
       FLOAT-based computed column cannot be indexed even when deterministic.
    5. Create a scalar UDF dbo.fn_TaskAgeDays(@CreatedAtUtc). Run a query using
       it and capture the plan and elapsed time. Then rewrite the same query with
       (a) the expression inline and (b) CROSS APPLY (VALUES (...)), and compare.
    6. Query sys.sql_modules.is_inlineable for your function. State your database's
       compatibility level and what it means for scalar UDF inlining.
    7. Force the un-inlined behaviour with
         OPTION (USE HINT('DISABLE_TSQL_SCALAR_UDF_INLINING'))
       and compare the plan with the inlined version. Note whether it is serial.
    8. Convert the scalar UDF into an INLINE TABLE-VALUED FUNCTION returning the
       same value, call it with CROSS APPLY, and explain why an iTVF is
       structurally cheaper than a scalar UDF.
    9. List the four independent reasons scalar UDFs are slow, and the four
       replacements from the Notes.
   10. Drop every object you created. Verify app.Tasks has no extra columns or
       indexes.

  HINTS
    - ALTER TABLE app.Tasks ADD CreatedYear AS (YEAR(CreatedAtUtc)) PERSISTED;
    - Dropping a computed column that has an index on it requires dropping the
      index FIRST.
    - SELECT compatibility_level FROM sys.databases WHERE name = DB_NAME();
      Inlining needs 150 or higher.
    - sys.sql_modules.is_inlineable is NULL for anything that is not a scalar UDF.
    - On 35 rows the timings are noise. Reason about PLAN SHAPE and about what
      happens at 35 million rows.

  CLEANUP: this script MUST leave app.Tasks exactly as it found it.
=============================================================================*/

USE TaskFlowDb;
GO

SET STATISTICS IO, TIME ON;
GO

-----------------------------------------------------------------------------
-- 1. Is app.Users.FullName deterministic? Why does that allow PERSISTED?
--    What would FORMAT do to the schema?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 2. Add + index a deterministic persisted computed column CreatedYear.
--    Show the UNCHANGED YEAR(...) predicate now matching the index.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 3. Attempt a NON-deterministic persisted computed column.
--    Capture the error verbatim and explain it.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 4. Deterministic vs precise. Why can a FLOAT computed column not be indexed?
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- 5a. Create dbo.fn_TaskAgeDays and use it. Capture the plan and timing.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 5b. The same query with the expression INLINE
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 5c. The same query with CROSS APPLY (VALUES (...)). Compare all three.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 6. sys.sql_modules.is_inlineable + this database's compatibility level.
--    What do they mean for scalar UDF inlining?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 7. Force un-inlined behaviour with USE HINT and compare the plans.
--    Is the plan serial?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 8. The inline table-valued function version, called with CROSS APPLY.
--    Why is an iTVF structurally cheaper than a scalar UDF?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 9. The four reasons scalar UDFs are slow, and the four replacements
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- 10. CLEANUP — leave TaskFlowDb exactly as you found it.
--     Index first, then the computed column, then the functions.
-----------------------------------------------------------------------------
DROP INDEX IF EXISTS IX_Tasks_CreatedYear ON app.Tasks;
GO
ALTER TABLE app.Tasks DROP COLUMN IF EXISTS CreatedYear;
GO
DROP FUNCTION IF EXISTS dbo.fn_TaskAgeDays;
DROP FUNCTION IF EXISTS dbo.itvf_TaskAgeDays;
GO

-- Verify app.Tasks is back to its original shape (15 columns, 1 index: PK_Tasks)
SELECT c.name AS ColumnName, c.column_id
FROM   sys.columns AS c
WHERE  c.object_id = OBJECT_ID('app.Tasks')
ORDER  BY c.column_id;

SELECT i.name AS IndexName, i.type_desc
FROM   sys.indexes AS i
WHERE  i.object_id = OBJECT_ID('app.Tasks') AND i.index_id > 0;
GO

SET STATISTICS IO, TIME OFF;
GO
