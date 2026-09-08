/*=============================================================================
  P3 — Character Types & Storage Math                           (Medium)
  Topic 02: Data Types & DDL
  -----------------------------------------------------------------------------
  Tags: char-varchar | nchar-nvarchar | utf8-collations | storage-math | lob

  PROBLEM
  -------
  1. For 'ada.lovelace@taskflow.io', compute the on-page byte cost under
     CHAR(256), VARCHAR(256), NCHAR(256), NVARCHAR(256), and VARCHAR(256) under
     a _UTF8 collation. Verify at least three with DATALENGTH.
  2. Prove CHAR padding: insert a short value into a CHAR(20) column on a
     scratch table and show DATALENGTH vs LEN. Explain why they disagree.
  3. Create a scratch table with one VARCHAR(50) column under the database
     default collation and one under Latin1_General_100_CI_AS_SC_UTF8. Insert an
     ASCII string and a string containing at least one non-Latin character.
     Compare DATALENGTH for each and explain the results.
  4. Explain, with a demonstration, why app.Labels.ColorHex is CHAR(7) and
     app.Users.Email is NVARCHAR(256). Would VARCHAR(320) under a UTF-8
     collation be better for Email? Argue both ways.
  5. Attempt to create a nonclustered index on app.Comments.Body (NVARCHAR(MAX)).
     Capture the error number and explain the index key size limits for
     clustered and nonclustered indexes.
  6. Show the practical difference between LEN, DATALENGTH and LTRIM(RTRIM()) on
     a padded CHAR value, and state which one detects over-declared columns.
  7. Write the ALTER TABLE that would change app.Projects.ProjectCode from
     VARCHAR(10) to NVARCHAR(10). Run it against a COPY, never app.Projects.
     Explain what it costs and what it breaks.

  DELIVERABLE
  -----------
  This file, with every query run and its output pasted underneath as a comment.

  HINTS
  -----
  - DATALENGTH returns bytes; LEN returns characters and IGNORES trailing spaces.
  - Index key size limits: 900 bytes clustered, 1,700 nonclustered (2016+).
  - Indexing an NVARCHAR(MAX) column fails with Msg 1919.
  - Make the copy with SELECT * INTO app.Projects_Copy FROM app.Projects; and
    drop it afterwards.
  - A UTF-8 collation makes ASCII 1 byte per character but non-Latin 2-4 bytes.
=============================================================================*/

USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  Step 1 — Byte cost of one email address under five declarations
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 2 — CHAR padding: DATALENGTH vs LEN on a scratch table
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 3 — Default collation vs _UTF8 collation: ASCII win, non-Latin loss
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4 — Why ColorHex is CHAR(7) and Email is NVARCHAR(256).
           Would VARCHAR(320) + UTF-8 be better for Email? Argue both ways.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 5 — Indexing NVARCHAR(MAX): capture Msg 1919 and state the key limits
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 6 — LEN vs DATALENGTH vs LTRIM(RTRIM()) on padded CHAR
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 7 — VARCHAR(10) -> NVARCHAR(10) on a COPY: the cost and what it breaks
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Cleanup — drop every scratch table and the Projects copy
-----------------------------------------------------------------------------*/
-- TODO: your solution here
