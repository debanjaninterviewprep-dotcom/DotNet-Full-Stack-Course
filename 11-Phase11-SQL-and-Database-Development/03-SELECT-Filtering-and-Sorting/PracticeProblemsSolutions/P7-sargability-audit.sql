/*=============================================================================
  Topic 03 — SELECT, Filtering & Sorting
  P7 — SARGability Audit and Plan Report                              (Hard)
  -----------------------------------------------------------------------------
  Tags: sargability, execution-plans, implicit-conversion, computed-columns,
        statistics-io

  PROBLEM
  You have inherited seven WHERE clauses from the TaskFlow reporting service.
  Audit and repair them.

      #1  WHERE YEAR(t.CreatedAtUtc) = 2025
      #2  WHERE CAST(t.CompletedAtUtc AS DATE) = '2024-02-28'
      #3  WHERE t.EstimatedHours * 2 > 40
      #4  WHERE LEFT(p.ProjectCode, 3) = 'TF-'
      #5  WHERE ISNULL(t.StoryPoints, 0) > 5
      #6  WHERE DATEDIFF(DAY, t.DueDate, '2025-09-01') > 30
      #7  WHERE p.ProjectCode = N'TF-CORE'

  REQUIREMENTS
    1. For each predicate: state WHY it is non-SARGable (or, for #7, what the
       hidden conversion is), then write a SARGable rewrite.
    2. Prove each rewrite is semantically identical using EXCEPT in BOTH
       directions — a pair of empty result sets is your proof.
    3. For #7, identify which side SQL Server converts and why, using data type
       precedence. State app.Projects.ProjectCode's declared type.
    4. For #7, explain how this bug typically arrives from a .NET application
       and name the concrete fix in both Dapper and EF Core.
    5. Create IX_Tasks_Created ON app.Tasks (CreatedAtUtc) INCLUDE (Title).
       Capture the actual plan operator (Index Seek / Index Scan / Key Lookup)
       and the SET STATISTICS IO logical reads for the original and rewritten
       versions of #1. Drop the index afterwards.
    6. Explain Seek Predicate vs Predicate (residual) using one of your rewrites.
    7. For #4's original form, describe the one situation in which you would keep
       an expression-based filter and index the expression instead — and name the
       TWO mechanisms SQL Server offers for that.
    8. Explain why 35 rows may still produce a scan for every query, and what
       that tells you about reading plans on toy data.

  HINTS
    - EXCEPT returns rows in the first set not present in the second. Run it
      both directions to prove set equality.
    - For #5, NULL > 5 is already UNKNOWN, so the ISNULL wrapper changes nothing
      about which rows match.
    - For #6, move the arithmetic to the literal:
          t.DueDate < DATEADD(DAY, -30, '2025-09-01')
    - The two expression-indexing mechanisms are PERSISTED COMPUTED COLUMNS
      (see app.Users.FullName) and INDEXED VIEWS.
    - Data type precedence: NVARCHAR outranks VARCHAR, so the VARCHAR side is
      converted.

  CLEANUP: this script MUST drop every index it creates.
=============================================================================*/

USE TaskFlowDb;
GO

-----------------------------------------------------------------------------
-- #1  YEAR(t.CreatedAtUtc) = 2025
--     Why non-SARGable? Rewrite. Prove equivalence with a two-way EXCEPT.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- #2  CAST(t.CompletedAtUtc AS DATE) = '2024-02-28'
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- #3  t.EstimatedHours * 2 > 40
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- #4  LEFT(p.ProjectCode, 3) = 'TF-'
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- #5  ISNULL(t.StoryPoints, 0) > 5
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- #6  DATEDIFF(DAY, t.DueDate, '2025-09-01') > 30
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- #7  p.ProjectCode = N'TF-CORE'
--     Which side is converted, and why? What is ProjectCode's declared type?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- #7 (cont.) How does this bug arrive from .NET?
--            Name the concrete Dapper fix and the concrete EF Core fix.
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- 5. Plan + logical reads for #1, original vs rewritten, with a real index.
--    CREATE IX_Tasks_Created, measure both forms, record the numbers, DROP it.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 6. Seek Predicate vs Predicate (residual) — explain using one of your rewrites
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- 7. When would you keep the expression and index it instead?
--    Name both mechanisms SQL Server offers.
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- 8. Why might 35 rows scan no matter what you write?
--    What does that tell you about reading plans on toy data?
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- CLEANUP — leave TaskFlowDb exactly as you found it
-----------------------------------------------------------------------------
DROP INDEX IF EXISTS IX_Tasks_Created ON app.Tasks;
GO
