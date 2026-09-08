/*=============================================================================
  P8 — Schema Migration Under Load                              (Hard)
  Topic 02: Data Types & DDL
  -----------------------------------------------------------------------------
  Tags: alter-column | online-ddl | expand-migrate-contract | locking |
        rollback | safety-checklist

  PROBLEM
  -------
  You are migrating app.Tasks.DueDate from DATE to a UTC instant, on a table
  that in production holds 40 million rows and is written to continuously.

  1. Classify each of the following as METADATA-ONLY or FULL REWRITE, and verify
     at least four against a COPY of app.Tasks:
       - NVARCHAR(200) -> NVARCHAR(400)
       - NVARCHAR(400) -> NVARCHAR(200)
       - NVARCHAR(200) -> NVARCHAR(MAX)
       - INT           -> BIGINT
       - VARCHAR(10)   -> NVARCHAR(10)
       - NULL          -> NOT NULL
       - NOT NULL      -> NULL
       - add a nullable column
       - add a NOT NULL column with a DEFAULT
       - drop a column
  2. Prove the NULLABILITY TRAP: on a copy, run ALTER COLUMN on a NOT NULL
     column without restating NOT NULL, then show from sys.columns that it
     became nullable. State the SET option responsible.
  3. Reproduce Msg 4901 by adding a NOT NULL column with no DEFAULT to a
     non-empty copy. Then do it correctly.
  4. Show that a column cannot be dropped while its DEFAULT constraint exists,
     capture the error, and write the correct two-statement sequence.
  5. Show that a column cannot be altered while an index references it. Create
     an index on a copy, attempt the alter, capture the error number, and write
     the drop-alter-recreate sequence.
  6. Write the full EXPAND / MIGRATE / CONTRACT migration for
     DueDate -> DueAtUtc DATETIME2(3), on a copy of app.Tasks:
       - Deploy 1: add the nullable column.
       - Deploy 2: backfill in batches of 1,000 with a bounded loop, reporting
         @@ROWCOUNT each pass. Explain why batching matters for the transaction
         log and for lock escalation.
       - Deploy 3: the contract step, plus exactly what must be true about the
         application before you run it.
     Write the ROLLBACK SCRIPT for each deploy.
  7. Explain what WITH (ONLINE = ON) does and does not do, which editions
     support it for ALTER COLUMN, and why you would still set LOCK_TIMEOUT.
  8. Write a query that finds every UNTRUSTED foreign key and check constraint,
     and explain what the optimizer stops doing when a constraint is untrusted.
  9. Produce your own SCHEMA-CHANGE SAFETY CHECKLIST as a comment block -- at
     least 10 items -- and mark which ones this migration would have failed
     without.
 10. Drop the copy and confirm app.Tasks is untouched.

  DELIVERABLE
  -----------
  This file, with every query run and its output pasted underneath as a comment.

  HINTS
  -----
  - Copy with: SELECT * INTO app.Tasks_Copy FROM app.Tasks;
    Note it deliberately does NOT bring the constraints -- convenient here, and
    a lesson in itself.
  - Msg 4901 is the missing-DEFAULT error; Msg 5074 is the
    "object is dependent on column" error for indexes and constraints.
  - ANSI_NULL_DFLT_ON governs the nullability fallback in ALTER COLUMN.
  - Batch loop shape:
      WHILE 1 = 1 BEGIN UPDATE TOP (1000) ... ; IF @@ROWCOUNT = 0 BREAK; END
  - Untrusted constraints: sys.foreign_keys.is_not_trusted and
    sys.check_constraints.is_not_trusted.
  - ONLINE = ON still takes a brief Sch-M lock at the end of the operation.
=============================================================================*/

USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  Setup — make the working copy
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 1 — Ten changes classified, at least four verified empirically
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 2 — The nullability trap, and the SET option responsible
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 3 — Msg 4901, then the correct form
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4 — A column cannot be dropped while its DEFAULT exists
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 5 — A column cannot be altered while an index references it (Msg 5074)
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 6 — EXPAND / MIGRATE / CONTRACT for DueDate -> DueAtUtc,
           with a rollback script for each deploy
-----------------------------------------------------------------------------*/
-- Deploy 1 (EXPAND)
-- TODO: your solution here


-- Deploy 1 ROLLBACK
-- TODO: your solution here


-- Deploy 2 (MIGRATE) -- batched backfill, with the log/lock-escalation rationale
-- TODO: your solution here


-- Deploy 2 ROLLBACK
-- TODO: your solution here


-- Deploy 3 (CONTRACT) -- plus the application precondition
-- TODO: your solution here


-- Deploy 3 ROLLBACK
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 7 — WITH (ONLINE = ON): what it does, editions, and why LOCK_TIMEOUT
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 8 — Untrusted foreign keys and check constraints, and what they cost
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 9 — Your schema-change safety checklist (10+ items), with the ones this
           migration would have failed marked
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 10 — Drop the copy and prove app.Tasks is untouched
-----------------------------------------------------------------------------*/
-- TODO: your solution here
