/*=============================================================================
  P3 — Key Inventory & Surrogate/Natural Audit                  (Easy)
  Topic 01: Relational Databases & SQL Fundamentals
  -----------------------------------------------------------------------------
  Tags: keys | primary-key | foreign-key | composite-key | surrogate-vs-natural

  PROBLEM
  -------
  1. Produce a KEY INVENTORY listing, for every app/ref/audit table: the primary
     key columns in key order, and every alternate (UNIQUE) key.
  2. Write a query listing ALL foreign keys with child table, parent table,
     ON DELETE action, and whether the FK is trusted.
  3. For app.Users, list EVERY candidate key you can justify from the data.
     Prove or disprove each with a GROUP BY ... HAVING COUNT(*) > 1 test.
  4. app.Projects has a surrogate PK (ProjectId) and a natural unique key
     (ProjectCode). Write the two ALTER TABLE statements that would migrate
     app.Tasks to reference ProjectCode instead, then argue in comments why you
     would not.
  5. Explain why audit.TaskHistory has NO foreign key to app.Tasks, and name one
     integrity risk you accept as a result.

  DELIVERABLE
  -----------
  This file, with every query run and its output pasted underneath as a comment.

  HINTS
  -----
  - PK/UQ columns: join sys.key_constraints -> sys.index_columns -> sys.columns
    on unique_index_id.
  - FKs: sys.foreign_keys has delete_referential_action_desc and is_not_trusted.
  - A candidate key must be MINIMAL: {UserId, Email} is a superkey, not a
    candidate key.
  - Test uniqueness of {FirstName, LastName} -- the data will tell you whether
    it holds today and whether it holds BY DESIGN.
=============================================================================*/

USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  Step 1 — Key inventory: PK columns in key order + every UNIQUE key
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 2 — Every foreign key: child, parent, ON DELETE action, trusted?
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 3 — Candidate keys of app.Users, each proved or disproved
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4 — The ProjectCode migration you would NOT do, plus the argument
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 5 — Why audit.TaskHistory has no FK, and the risk you accept
-----------------------------------------------------------------------------*/
-- TODO: your solution here
