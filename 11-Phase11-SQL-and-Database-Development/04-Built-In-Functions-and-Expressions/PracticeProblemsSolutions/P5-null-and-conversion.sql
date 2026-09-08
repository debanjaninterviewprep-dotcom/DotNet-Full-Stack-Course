/*=============================================================================
  Topic 04 — Built-In Functions & Expressions
  P5 — NULL Handling and Safe Conversion                            (Medium)
  -----------------------------------------------------------------------------
  Tags: isnull, coalesce, nullif, try-convert, try-parse, implicit-conversion,
        ansi-nulls

  REQUIREMENTS
    1. Reproduce the ISNULL truncation trap:
         ISNULL(CAST(NULL AS VARCHAR(2)), 'abcdef')  vs  the COALESCE equivalent.
       Explain the return-type rule for each.
    2. Show that SELECT COALESCE(NULL, NULL) errors while SELECT ISNULL(NULL, NULL)
       does not. Record the error message.
    3. Write the CASE expansion of COALESCE(a, b) and explain the double-evaluation
       consequence. Give a concrete TaskFlow example where the repeated expression
       is a scalar subquery.
    4. Explain the NULLABILITY difference and why it matters for a PERSISTED
       computed column.
    5. Build a display projection over ref.Priorities where a NULL SlaHours renders
       as an em dash, and over app.Users where a NULL HourlyRate renders as
       'Not set'. Get the types right — no implicit-conversion errors.
    6. Use NULLIF three ways:
         a) divide-by-zero protection on EstimatedHours / StoryPoints
         b) turning CHARINDEX's 0 into a real NULL
         c) normalising an empty string in audit.TaskHistory.NewValue to NULL
    7. Use TRY_CONVERT to parse audit.TaskHistory.NewValue as an INT, and explain
       what TRY_CAST still errors on.
    8. Demonstrate the implicit-conversion bug:
         WHERE p.ProjectCode = N'TF-CORE'   vs   = 'TF-CORE'
       State ProjectCode's declared type, which side gets converted and why, and
       name the fix in ADO.NET, Dapper and EF Core.
    9. Explain what SET ANSI_NULLS OFF does, why it is deprecated, and how a
       legacy stored procedure can behave differently from the same SQL run ad-hoc.

  HINTS
    - ref.Priorities.SlaHours is SMALLINT, NULL for PriorityId = 5.
    - app.Users.HourlyRate is DECIMAL(9,2), NULL for UserId 19.
    - audit.TaskHistory is EMPTY in a fresh database — insert a couple of rows
      yourself for requirements 6c and 7, then delete them.
    - ISNULL result nullability is inferred NOT NULL when the second argument is
      non-nullable; COALESCE generally is not.
    - Data type precedence: NVARCHAR outranks VARCHAR.

  CLEANUP: delete any audit.TaskHistory rows you insert.
=============================================================================*/

USE TaskFlowDb;
GO

-----------------------------------------------------------------------------
-- 1. The ISNULL truncation trap. State the return-type rule for each function.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 2. COALESCE(NULL, NULL) errors; ISNULL(NULL, NULL) does not.
--    Record the error message.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 3. The CASE expansion of COALESCE(a, b) and the double-evaluation risk.
--    Give a concrete example where 'a' is a scalar subquery.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 4. Nullability difference — and why it matters for PERSISTED computed columns
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- 5. Display projections: NULL SlaHours -> em dash; NULL HourlyRate -> 'Not set'
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 6. NULLIF three ways (divide-by-zero, CHARINDEX 0, empty-string normalisation)
--    Insert a couple of audit.TaskHistory rows first; delete them at the end.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 7. TRY_CONVERT over audit.TaskHistory.NewValue.
--    What does TRY_CAST still raise an error on?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 8. Implicit conversion: N'TF-CORE' vs 'TF-CORE' on app.Projects.ProjectCode.
--    Which side is converted, and why? Name the ADO.NET, Dapper and EF Core fixes.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 9. SET ANSI_NULLS OFF: what it does, why it is deprecated, and how a legacy
--    stored procedure can behave differently from the same ad-hoc SQL.
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- CLEANUP — remove any audit rows you inserted
-----------------------------------------------------------------------------

-- TODO: your cleanup here
GO
