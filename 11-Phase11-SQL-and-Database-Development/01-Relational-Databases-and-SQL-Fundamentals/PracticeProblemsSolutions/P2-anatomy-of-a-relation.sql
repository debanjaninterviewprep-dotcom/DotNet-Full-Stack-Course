/*=============================================================================
  P2 — Anatomy of a Relation                                    (Easy)
  Topic 01: Relational Databases & SQL Fundamentals
  -----------------------------------------------------------------------------
  Tags: relational-model | degree-cardinality | catalog-views | atomicity

  PROBLEM
  -------
  1. Write ONE query returning, for every table in the app, ref and audit
     schemas: schema name, table name, DEGREE (column count) and CARDINALITY
     (row count). Order by cardinality descending.
  2. Prove the "no guaranteed order" property: run
     `SELECT TOP (5) TaskId FROM app.Tasks;` twice -- once as written, once with
     `ORDER BY NEWID()` -- and explain why neither result is a contract.
  3. Identify the DOMAIN of app.Tasks.StatusId: name the base type, its storage
     size, and the two mechanisms that narrow the domain beyond the type.
  4. app.Tasks.MetadataJson stores JSON in one column. Argue in 4-6 lines
     whether this violates first normal form, and state the condition under
     which it does.
  5. Show that SELECT returns a MULTISET: produce a query over app.TeamMembers
     that returns duplicate rows, then the DISTINCT version.

  DELIVERABLE
  -----------
  This file, with every query run and its output pasted underneath as a comment.

  HINTS
  -----
  - Cardinality without a scan: sys.partitions WHERE index_id IN (0, 1),
    summing `rows`.
  - Degree: sys.columns grouped by object_id.
  - TINYINT is 1 byte, range 0-255. The two narrowing mechanisms are NOT NULL
    and a constraint.
  - For duplicates, project only Department from a join of app.TeamMembers to
    app.Teams.
=============================================================================*/

USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  Step 1 — Degree and cardinality for every app/ref/audit table (ONE query)
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 2 — No guaranteed order: TOP without ORDER BY, and ORDER BY NEWID()
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 3 — The domain of app.Tasks.StatusId
           Base type, storage bytes, and the two narrowing mechanisms.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4 — Does app.Tasks.MetadataJson violate 1NF? (4-6 lines)
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 5 — SELECT returns a multiset: duplicates, then DISTINCT
-----------------------------------------------------------------------------*/
-- TODO: your solution here
