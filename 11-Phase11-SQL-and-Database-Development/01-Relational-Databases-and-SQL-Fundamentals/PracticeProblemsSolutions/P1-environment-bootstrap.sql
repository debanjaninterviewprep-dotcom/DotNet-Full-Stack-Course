/*=============================================================================
  P1 — Environment Bootstrap & Instance Reconnaissance          (Easy)
  Topic 01: Relational Databases & SQL Fundamentals
  -----------------------------------------------------------------------------
  Tags: docker | tooling | system-databases | engine-architecture

  PROBLEM
  -------
  1. Start a SQL Server 2022 container named `taskflow-sql` on port 1433, with a
     NAMED VOLUME so data survives `docker restart`. Use the Developer edition PID.
  2. Connect with at least TWO different tools (sqlcmd plus one of SSMS /
     Azure Data Studio / VS Code `ms-mssql.mssql`).
  3. Run 00-create-taskflow-db.sql and confirm the row counts match the expected
     block at the bottom of that script.
  4. Capture, as a single result set where possible:
       - @@VERSION, the product edition, and the product level.
       - The server collation and the TaskFlowDb collation.
       - All system databases with database_id, state_desc, recovery_model_desc.
       - The physical file names and sizes (MB) of TaskFlowDb.
  5. Explain in a comment why the 2022 container image needs `-C` on sqlcmd and
     what that flag actually disables.

  DELIVERABLE
  -----------
  This file: the container command as a comment block, all reconnaissance
  queries, and the captured output pasted under each query as a comment.

  HINTS
  -----
  - SERVERPROPERTY('Edition'), SERVERPROPERTY('ProductLevel'),
    SERVERPROPERTY('Collation').
  - DATABASEPROPERTYEX(N'TaskFlowDb', 'Collation').
  - sys.databases: database_id 1-4 are the system databases.
  - sys.database_files.size is in 8 KB pages, so `size * 8 / 1024` is MB.
  - If the container exits immediately, `docker logs taskflow-sql` almost always
    says the SA password failed policy.
=============================================================================*/

/*-----------------------------------------------------------------------------
  Step 1 — Container command (paste your exact, reproducible command here)
-----------------------------------------------------------------------------*/
-- TODO: your solution here


USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  Step 3 — Verify the seeded row counts
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4a — Version, edition, product level
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4b — Server collation vs database collation
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4c — System databases: id, state, recovery model, and what each is FOR
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4d — TaskFlowDb physical files and sizes in MB
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 5 — Why does sqlcmd need -C against the 2022 image?
           What does the flag disable, and why is it dev-only?
-----------------------------------------------------------------------------*/
-- TODO: your solution here
