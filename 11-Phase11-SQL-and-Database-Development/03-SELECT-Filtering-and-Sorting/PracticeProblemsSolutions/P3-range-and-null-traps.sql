/*=============================================================================
  Topic 03 — SELECT, Filtering & Sorting
  P3 — Ranges, Sets and the NULL Traps                              (Medium)
  -----------------------------------------------------------------------------
  Tags: between, date-ranges, in, not-in, null, not-exists, anti-join

  PROBLEM
  Two bugs from the TaskFlow issue tracker. Reproduce both, then fix both.

  BUG 1 — "The February report is missing a task."
    1. Run  WHERE t.CompletedAtUtc BETWEEN '2024-02-01' AND '2024-02-28'
       against app.Tasks. Record the rows returned.
    2. Identify by TaskId the row that SHOULD be there and is not, and explain
       exactly why in a comment.
    3. Rewrite using a half-open interval so the result is correct. Prove it
       returns the missing row.
    4. Show — and explain the downside of — the CAST(t.CompletedAtUtc AS DATE)
       "fix".

  BUG 2 — "The 'users who never led a team' report returns nothing."
    5. Run  WHERE u.UserId NOT IN (SELECT tm.LeadUserId FROM app.Teams AS tm)
       against app.Users. Record the row count.
    6. Explain the expansion of NOT IN for a single candidate row, showing
       where UNKNOWN enters.
    7. Fix it THREE ways: NOT EXISTS, an IS NOT NULL filter on the inner query,
       and a LEFT JOIN ... IS NULL anti-join. All three must return the same rows.
    8. State which one you would ship and why.

  HINTS
    - app.Tasks.CompletedAtUtc is DATETIME2(3); a bare date literal is midnight.
    - app.Teams has one row ('Design System') with a NULL LeadUserId.
    - The correct answer set for Bug 2 has 14 users.
    - Prove set equality with EXCEPT run in BOTH directions.
=============================================================================*/

USE TaskFlowDb;
GO

-----------------------------------------------------------------------------
-- BUG 1.1 — Reproduce: BETWEEN on a DATETIME2 column. Record the row count.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- BUG 1.2 — Which TaskId is missing, and why?
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- BUG 1.3 — Half-open interval fix. Prove the missing row now appears.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- BUG 1.4 — The CAST(... AS DATE) alternative and its downside
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- BUG 2.5 — Reproduce: NOT IN over a nullable column. Record the row count.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- BUG 2.6 — Write out the NOT IN expansion for one candidate row.
--           Show exactly where UNKNOWN enters.
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- BUG 2.7a — Fix with NOT EXISTS
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- BUG 2.7b — Fix by filtering NULLs out of the inner query
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- BUG 2.7c — Fix with a LEFT JOIN ... IS NULL anti-join
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- BUG 2.7d — Prove all three return an identical set (EXCEPT, both directions)
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- BUG 2.8 — Which fix would you ship, and why?
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)
GO
