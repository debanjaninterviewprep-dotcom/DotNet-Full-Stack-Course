/*=============================================================================
  P5 — Implicit Conversion & SARGability Hunt                   (Medium)
  Topic 02: Data Types & DDL
  -----------------------------------------------------------------------------
  Tags: type-precedence | implicit-conversion | sargability | execution-plans |
        ado-net

  PROBLEM
  -------
  1. Write out the data type precedence order from sql_variant down to binary as
     a comment. Verify THREE adjacent pairs with a SELECT that shows which type
     the result takes (use SQL_VARIANT_PROPERTY(..., 'BaseType')).
  2. Reproduce the VARCHAR / NVARCHAR trap on app.Projects.ProjectCode. Run the
     query both ways with the actual execution plan on. Find CONVERT_IMPLICIT in
     the plan and state which SIDE of the predicate it is applied to.
  3. Do the same for ref.TaskStatuses.StatusCode (VARCHAR(20)) and explain why
     the effect is more damaging on a large table than on a 7-row lookup.
  4. Show three more non-SARGable patterns against app.Tasks and rewrite each
     SARGably:
       - a function on the column      : YEAR(t.DueDate) = 2025
       - arithmetic on the column      : t.EstimatedHours * 2 > 40
       - a leading wildcard            : t.Title LIKE N'%pagination%'
     For the third, state what you would need in order to make it fast.
  5. Show integer division surprising you: SELECT 5 / 2; versus SELECT 5 / 2.0;
     Then find a real TaskFlow ratio where the same mistake would produce a
     wrong business number, and fix it.
  6. Explain how this bug reaches SQL Server from .NET. Write the two lines of
     EF Core Fluent API configuration and the one SqlParameter property that
     prevent it.
  7. Write a catalog query that lists every VARCHAR / CHAR column in app and ref
     -- the columns most at risk from an NVARCHAR parameter.

  DELIVERABLE
  -----------
  This file, with every query run and its output pasted underneath as a comment.

  HINTS
  -----
  - SELECT SQL_VARIANT_PROPERTY(CAST(1 AS TINYINT) + CAST(1 AS INT), 'BaseType');
  - Actual plan: SET STATISTICS XML ON in sqlcmd, or Ctrl+M in SSMS / ADS.
  - At-risk columns: ProjectCode, StatusCode, PriorityCode, CountryCode, ColorHex.
  - EF Core: .IsUnicode(false) or .HasColumnType("varchar(10)").
    ADO.NET: SqlDbType.VarChar.
  - A leading wildcard needs full-text search or an n-gram index -- no B-tree
    can seek it.
=============================================================================*/

USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  Step 1 — Precedence order, with three adjacent pairs verified
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 2 — The ProjectCode trap: N'TF-CORE' vs 'TF-CORE', with the plan
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 3 — The same on ref.TaskStatuses.StatusCode, and why scale changes the
           severity
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4 — Three non-SARGable patterns and their SARGable rewrites
-----------------------------------------------------------------------------*/
-- 4a. Function on the column
-- TODO: your solution here


-- 4b. Arithmetic on the column
-- TODO: your solution here


-- 4c. Leading wildcard -- and what would actually be needed
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 5 — Integer division, and a real TaskFlow ratio it would corrupt
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 6 — How this arrives from .NET: the EF Core and ADO.NET fixes
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 7 — Every VARCHAR / CHAR column in app and ref: the at-risk list
-----------------------------------------------------------------------------*/
-- TODO: your solution here
