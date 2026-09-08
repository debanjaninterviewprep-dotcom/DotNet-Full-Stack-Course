/*=============================================================================
  P6 — Three-Valued Logic Audit                                 (Medium)
  Topic 01: Relational Databases & SQL Fundamentals
  -----------------------------------------------------------------------------
  Tags: null | three-valued-logic | not-in | aggregates | constraints

  PROBLEM
  -------
  1. Write the complete truth tables for AND, OR and NOT over
     {TRUE, FALSE, UNKNOWN} as a comment block, then verify three of the rows
     with actual SELECT statements.
  2. For ref.Priorities, show the difference between `= NULL` and `IS NULL`, and
     between COUNT(*) and COUNT(SlaHours). Explain the numbers.
  3. Write a query intended to return "all priorities whose SLA is not 24
     hours". Show the naive version, state how many rows it silently loses, and
     write the correct version.
  4. Reproduce the NOT IN trap: write "users who manage nobody" using NOT IN
     over app.Users.ManagerId -- it will return zero rows. Explain precisely
     why, then fix it with NOT EXISTS. Also show the NOT IN version made correct
     by filtering NULLs, and say which fix you prefer and why.
  5. Show that GROUP BY, DISTINCT and UNIQUE treat NULLs as EQUAL even though
     `=` does not. Use ref.Priorities.SlaHours and app.Users.ManagerId.
  6. CK_Users_HourlyRate is CHECK (HourlyRate IS NULL OR HourlyRate >= 0). Prove
     the IS NULL half is redundant by attempting a NULL insert against a
     CHECK (HourlyRate >= 0) on a scratch table. Explain the WHERE/CHECK
     asymmetry.
  7. Produce a NULLABILITY REPORT: every nullable column in the app and ref
     schemas, with its actual NULL count and the percentage of rows affected.

  DELIVERABLE
  -----------
  This file, with every query run and its output pasted underneath as a comment.

  HINTS
  -----
  - Users 1 and 20 have ManagerId IS NULL. That is what poisons NOT IN.
  - SELECT CASE WHEN NULL = NULL THEN 'T'
                WHEN NOT (NULL = NULL) THEN 'F'
                ELSE 'UNKNOWN' END;
  - For the nullability report, drive off sys.columns WHERE is_nullable = 1 and
    build the counts with dynamic SQL OR hand-write the union -- say which you
    chose and why dynamic SQL is a security consideration (Topic 19).
  - Clean up any scratch table with DROP TABLE IF EXISTS.
=============================================================================*/

USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  Step 1 — Truth tables for AND / OR / NOT, plus three verifying SELECTs
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 2 — `= NULL` vs `IS NULL`; COUNT(*) vs COUNT(SlaHours)
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 3 — "SLA is not 24 hours": naive version, rows lost, correct version
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4 — The NOT IN trap, the NOT EXISTS fix, the IS NOT NULL fix,
           and your preference with a reason
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 5 — GROUP BY / DISTINCT / UNIQUE treat NULLs as equal
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 6 — CHECK rejects only FALSE; WHERE keeps only TRUE.
           Scratch table proof, then DROP TABLE IF EXISTS.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 7 — Nullability report: nullable columns, NULL counts, percentages
-----------------------------------------------------------------------------*/
-- TODO: your solution here
