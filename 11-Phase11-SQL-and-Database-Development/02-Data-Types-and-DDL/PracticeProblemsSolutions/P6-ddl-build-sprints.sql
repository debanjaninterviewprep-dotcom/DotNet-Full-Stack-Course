/*=============================================================================
  P6 — Design and Build app.Sprints                             (Medium)
  Topic 02: Data Types & DDL
  -----------------------------------------------------------------------------
  Tags: create-table | schemas | defaults | identity-vs-sequence |
        computed-columns | naming-conventions | sparse-columns

  PROBLEM
  -------
  TaskFlow is adding sprints. Design and build the schema.

  1. Create app.Sprints with, at minimum: a surrogate key, a foreign key to
     app.Projects, a name, start and end dates, an optional capacity in hours, a
     closed flag, and a UTC creation timestamp. Justify EVERY type choice in a
     comment.
  2. Every constraint must be EXPLICITLY NAMED following the
     PK_ / FK_ / UQ_ / CK_ / DF_ convention. Add:
       - a unique constraint preventing two sprints with the same name in the
         same project,
       - a check constraint that the end date is not before the start date,
       - defaults for the closed flag and the creation timestamp.
  3. Add a PERSISTED computed column DurationDays. Then attempt to add a
     NON-DETERMINISTIC computed column (DaysRemaining based on SYSUTCDATETIME())
     as PERSISTED, capture the error number, and add the working non-persisted
     version instead.
  4. Create app.SprintTasks as a junction table between app.Sprints and
     app.Tasks with a composite primary key and appropriate cascade behaviour.
     Justify the cascade choice.
  5. Add an optional ExternalSprintRef NVARCHAR(64) as a SPARSE column. State
     the break-even NULL percentage for that type and whether it is justified.
  6. Demonstrate IDENTITY vs SEQUENCE: populate three sprints using IDENTITY,
     then create app.SprintNumberSeq and show NEXT VALUE FOR producing a number
     BEFORE any row exists. State one scenario where only the sequence works.
  7. Prove that identity values leak: insert inside a transaction, roll back,
     insert again, and show the gap. Then run DBCC CHECKIDENT (..., NORESEED).
  8. Use SET IDENTITY_INSERT to insert a sprint with a specific id, then turn it
     off. Explain the one-table-per-session rule.
  9. Capture generated keys correctly for a MULTI-ROW insert using
     OUTPUT INSERTED.SprintId. Explain why SCOPE_IDENTITY() cannot do this and
     why @@IDENTITY is wrong even for one row.
 10. Drop everything you created.

  DELIVERABLE
  -----------
  This file, with every query run and its output pasted underneath as a comment.

  HINTS
  -----
  - The non-deterministic PERSISTED failure is Msg 4936.
  - DATEDIFF(DAY, StartDate, EndDate) + 1 is deterministic, so it can persist.
  - Sparse columns cannot be NOT NULL and cannot have a DEFAULT.
  - sys.sequences exposes current_value, increment and cache_size.
  - Only ONE table per session may have IDENTITY_INSERT set to ON.
  - Drop child tables before parents, and DEFAULT constraints before columns.
=============================================================================*/

USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  Step 1 + 2 — CREATE TABLE app.Sprints, every constraint explicitly named,
               every type choice justified in a comment
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 3 — PERSISTED DurationDays; then Msg 4936 on a non-deterministic
           PERSISTED column; then the working non-persisted version
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4 — app.SprintTasks junction table, composite PK, justified cascade
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 5 — SPARSE ExternalSprintRef: break-even NULL percentage and the verdict
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 6 — IDENTITY vs SEQUENCE, and the scenario only SEQUENCE handles
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 7 — Prove identity values leak on ROLLBACK; then DBCC CHECKIDENT NORESEED
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 8 — SET IDENTITY_INSERT, and the one-table-per-session rule
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 9 — OUTPUT INSERTED for a multi-row insert.
           Why SCOPE_IDENTITY() cannot do it, and why @@IDENTITY is wrong.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 10 — Cleanup: drop everything, children first
-----------------------------------------------------------------------------*/
-- TODO: your solution here
