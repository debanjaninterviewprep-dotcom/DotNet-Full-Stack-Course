/*=============================================================================
  P7 — Batches, Identifiers, Collation & Case Sensitivity       (Hard)
  Topic 01: Relational Databases & SQL Fundamentals
  -----------------------------------------------------------------------------
  Tags: batches | go | identifiers | quoted-identifier | collation | sargability

  PROBLEM
  -------
  1. Demonstrate BATCH SCOPING: declare a variable, use it, then attempt to use
     it after a GO. Capture the message number. Then show that a #temp table
     DOES survive GO and explain the difference in scope.
  2. Use `GO 3` to insert three rows into audit.TaskHistory with
     ColumnName = N'BatchDemo', verify the count, then clean up.
  3. Explain, with a working example, why 00-create-taskflow-db.sql wraps
     CREATE SCHEMA in EXEC (N'CREATE SCHEMA app'). Reproduce the error you get
     without the wrapper.
  4. Create a scratch table using RESERVED WORDS as the table and column names
     ([Order], [User], [Group]), insert a row, select from it, and drop it.
     Then write 3 lines on why you would never ship this.
  5. Toggle SET QUOTED_IDENTIFIER OFF and show that "Title" changes meaning from
     a column reference to a string literal. Restore ON afterwards and explain
     which features require it.
  6. Report the server collation, the database collation, and any column-level
     collations in app. Then:
       - Show ProjectCode = 'tf-core' matching under the default collation.
       - Force a case-sensitive comparison with COLLATE and show zero rows.
       - Explain why the COLLATE version is NON-SARGABLE and what you would do
         instead if this were a hot path.
  7. Write a query proving whether the TaskFlowDb collation is accent sensitive,
     using a literal comparison such as N'Turing' = N'Türing'.

  DELIVERABLE
  -----------
  This file, with every query run and its output pasted underneath as a comment.

  HINTS
  -----
  - Batch-scope failure is Msg 137. The CREATE SCHEMA failure is Msg 111.
  - sys.columns.collation_name is NULL for non-character columns.
  - SARGability: a function or COLLATE applied to the COLUMN side prevents an
    index seek; applied to the LITERAL side it does not -- but the comparison
    collation still has to match.
  - The correct fix for a hot path is a persisted, normalised column or a
    column-level collation change -- not per-query COLLATE.
=============================================================================*/

USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  Step 1 — Batch scope: variables die at GO, #temp tables do not
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 2 — GO 3 against audit.TaskHistory, verify, then clean up
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 3 — Why CREATE SCHEMA is wrapped in EXEC (reproduce Msg 111)
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4 — Reserved words as identifiers: [Order], [User], [Group]
           Create, insert, select, drop -- then 3 lines on why never to ship it.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 5 — QUOTED_IDENTIFIER ON vs OFF, and which features require ON
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 6 — Collations: server, database, column-level.
           CI match, forced CS comparison, and the SARGability explanation.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 7 — Is TaskFlowDb accent sensitive? Prove it.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Cleanup — every scratch object dropped, audit.TaskHistory back to 0 rows
-----------------------------------------------------------------------------*/
-- TODO: your solution here
