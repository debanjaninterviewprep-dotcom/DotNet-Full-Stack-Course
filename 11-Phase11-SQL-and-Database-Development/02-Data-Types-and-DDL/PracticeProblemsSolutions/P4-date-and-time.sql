/*=============================================================================
  P4 — Date, Time and the Timezone Contract                     (Medium)
  Topic 02: Data Types & DDL
  -----------------------------------------------------------------------------
  Tags: date-time-types | datetime2 | datetimeoffset | at-time-zone | sargability

  PROBLEM
  -------
  1. Build the comparison table for DATE, TIME(7), SMALLDATETIME, DATETIME,
     DATETIME2(3), DATETIME2(7) and DATETIMEOFFSET(3): range, accuracy, storage
     bytes. Verify the storage bytes from sys.columns on a scratch table.
  2. Reproduce the DATETIME rounding bug: cast '2025-09-08T23:59:59.999' to
     DATETIME and to DATETIME2(3) and show that one of them changes the DATE.
     Explain the 3.33 ms rounding rule.
  3. Show the SMALLDATETIME failure mode: store a value with seconds and show
     what comes back. State its range limit and why 2079 is a real problem for
     anything with a retention policy.
  4. Write the "tasks completed in June 2024" query THREE ways: with BETWEEN and
     a '...23:59:59.997' upper bound, with YEAR()/MONTH(), and with a half-open
     range. Rank them for correctness and SARGability, and justify the ranking.
  5. Convert app.Tasks.CompletedAtUtc to two named time zones using AT TIME ZONE,
     for all completed tasks. Show a row where the local DATE differs from the
     UTC date.
  6. Demonstrate SWITCHOFFSET and TODATETIMEOFFSET, and explain the difference
     between them in one line each.
  7. Argue in 6-10 lines whether app.Tasks.DueDate should become DATETIMEOFFSET.
     Consider a distributed team, "due end of day", and what breaks in reporting.
  8. app.Tasks.CreatedAtUtc is DATETIME2(3). Show the storage saving versus
     DATETIME2(7) across the whole table, and state whether the extra precision
     would ever be observable.

  DELIVERABLE
  -----------
  This file, with every query run and its output pasted underneath as a comment.

  HINTS
  -----
  - DATETIME rounds to increments of .000, .003 and .007 seconds.
  - AT TIME ZONE needs the value to be zone-aware first:
      col AT TIME ZONE 'UTC' AT TIME ZONE 'India Standard Time'
  - SWITCHOFFSET changes the presented offset of an existing DATETIMEOFFSET;
    TODATETIMEOFFSET attaches an offset to a naive DATETIME2.
  - SELECT name FROM sys.time_zone_info; lists every zone the server knows.
  - DATETIME2(3) is 7 bytes; DATETIME2(7) is 8.
=============================================================================*/

USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  Step 1 — Range / accuracy / storage for seven date-time types, verified
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 2 — The DATETIME rounding bug that changes the DATE
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 3 — SMALLDATETIME: minute accuracy and the 2079 ceiling
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4 — "Completed in June 2024", three ways. Rank and justify.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 5 — AT TIME ZONE into two named zones; find a row where the DATE differs
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 6 — SWITCHOFFSET vs TODATETIMEOFFSET
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 7 — Should DueDate become DATETIMEOFFSET? Reach a decision.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 8 — DATETIME2(3) vs DATETIME2(7) storage across app.Tasks
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Cleanup — drop every scratch table
-----------------------------------------------------------------------------*/
-- TODO: your solution here
