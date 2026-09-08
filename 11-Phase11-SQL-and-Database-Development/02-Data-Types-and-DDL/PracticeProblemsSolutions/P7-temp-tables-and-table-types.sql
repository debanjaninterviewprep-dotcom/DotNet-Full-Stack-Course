/*=============================================================================
  P7 — Temp Tables, Table Variables, Table Types & SELECT INTO   (Hard)
  Topic 02: Data Types & DDL
  -----------------------------------------------------------------------------
  Tags: temp-tables | table-variables | table-types | tvp | select-into |
        statistics

  PROBLEM
  -------
  1. Build the same overdue-task result set FOUR ways: a #temp table, a ##global
     temp table, a @table variable, and a CTE. For each, record: where it lives,
     its scope, whether it has statistics, and whether ROLLBACK undoes it.
  2. Prove the SCOPE differences:
       - a #temp table survives GO but not a new session,
       - a @table variable does NOT survive GO (capture the message number),
       - a ##global temp table is visible from a second connection.
  3. Prove that a @table variable is NOT rolled back: insert into both a #temp
     and a @table inside an explicit transaction, roll back, and show the counts.
  4. Show the STATISTICS difference. Load ~35 rows into a #temp and a @table,
     join each to app.Tasks, and compare estimated versus actual row counts in
     the plans. Explain the one-row estimate.
  5. Add a clustered index to the #temp table AFTER creation, then show that the
     equivalent must be declared INLINE for a table variable. Write both.
  6. Create app.TaskIdList as a table type, write a procedure that takes it as a
     READONLY TVP, and call it with three task ids. Explain why TVPs are always
     read-only and what that means for a .NET caller.
  7. Contrast SELECT INTO and INSERT INTO ... SELECT:
       - use SELECT INTO to snapshot app.Tasks, then query sys.columns to show
         which constraints, defaults and indexes did NOT come along,
       - build the same snapshot with an explicit CREATE TABLE plus
         INSERT INTO ... SELECT,
       - show that SELECT INTO INFERS the type of an expression column, and find
         one inference you would not have chosen.
  8. State which of the four structures you would use for: 20 rows, 20,000 rows,
     passing a set from .NET, and data that must survive a ROLLBACK. Justify each.
  9. Drop everything.

  DELIVERABLE
  -----------
  This file, with every query run and its output pasted underneath as a comment.

  HINTS
  -----
  - The table-variable-after-GO failure is Msg 1087.
  - tempdb.sys.columns with OBJECT_ID(N'tempdb..#YourTable') inspects inferred
    types.
  - Table variables have no statistics; 2019+ deferred compilation improves the
    estimate but does not create statistics.
  - Inline index syntax: INDEX IX_Name NONCLUSTERED (Col) inside DECLARE @t TABLE.
  - A ##global temp table needs a second connection to demonstrate.
=============================================================================*/

USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  Step 1 — The same overdue-task set four ways, with the comparison recorded
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 2 — Scope: #temp across GO, @table across GO (Msg 1087), ##global across
           connections
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 3 — ROLLBACK asymmetry: #temp is undone, @table is not
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4 — Statistics: estimated vs actual rows for #temp and @table
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 5 — Index after creation (#temp) vs inline index (@table)
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 6 — Table type + READONLY TVP + procedure, called with three ids
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 7 — SELECT INTO vs INSERT INTO ... SELECT
           7a. SELECT INTO snapshot, then what did NOT come along
           7b. Explicit CREATE TABLE + INSERT INTO ... SELECT
           7c. An inferred type you would not have chosen
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 8 — Which structure for: 20 rows / 20,000 rows / a set from .NET /
           data that must survive ROLLBACK. Justify each.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 9 — Cleanup: every temp table, type, procedure and snapshot dropped
-----------------------------------------------------------------------------*/
-- TODO: your solution here
