/*=============================================================================
  P2 — Numeric Precision Lab                                    (Easy)
  Topic 02: Data Types & DDL
  -----------------------------------------------------------------------------
  Tags: decimal-precision-scale | money | float | rounding

  PROBLEM
  -------
  1. Build a table of TINYINT / SMALLINT / INT / BIGINT showing range and
     storage bytes. Verify TWO of the boundaries by attempting an out-of-range
     insert into a scratch table and capturing the error number.
  2. Demonstrate the MONEY truncation problem: show a division where MONEY loses
     all precision and DECIMAL(19,4) does not. Explain WHY, in terms of
     intermediate results.
  3. Demonstrate that FLOAT breaks equality: show an expression where FLOAT
     arithmetic is not equal to the literal it should equal, and the DECIMAL
     equivalent that is.
  4. Show the DECIMAL storage tiers. Create a scratch table with DECIMAL(9,2),
     DECIMAL(19,4), DECIMAL(28,6) and DECIMAL(38,10) columns and confirm the
     byte cost of each from sys.columns.
  5. Compute total billable value per project from app.TimeEntries.Hours and
     app.Users.HourlyRate. Report the RESULT TYPE of the multiplication and
     explain how SQL Server derived its precision and scale.
  6. Repeat question 5 with both operands cast to FLOAT and show that the two
     results differ. Quantify the difference.
  7. app.Tasks.StoryPoints is TINYINT. Write the query that would fail if a team
     adopted a scale reaching 300, and state the error.

  DELIVERABLE
  -----------
  This file, with every query run and its output pasted underneath as a comment.

  HINTS
  -----
  - Out-of-range integer insert is Msg 220 (arithmetic overflow) or Msg 8115.
  - DECLARE @m MONEY = 0.0001; SELECT @m / 3;
  - Multiplication: scale = s1 + s2, precision = p1 + p2 + 1, capped at 38.
  - sys.columns.precision, .scale and .max_length reveal the storage tier.
  - Join app.TimeEntries to app.Users on UserId, then to app.Tasks and
    app.Projects.
=============================================================================*/

USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  Step 1 — Integer ranges and storage, with two boundaries verified empirically
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 2 — MONEY truncates intermediate results; DECIMAL does not
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 3 — FLOAT breaks equality; DECIMAL does not
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4 — DECIMAL storage tiers: 5 / 9 / 13 / 17 bytes, confirmed from catalog
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 5 — Billable value per project, plus the derived precision and scale
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 6 — The same computation in FLOAT. Quantify the difference in currency.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 7 — The TINYINT ceiling: the query that fails at StoryPoints = 300
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Cleanup — drop every scratch table
-----------------------------------------------------------------------------*/
-- TODO: your solution here
