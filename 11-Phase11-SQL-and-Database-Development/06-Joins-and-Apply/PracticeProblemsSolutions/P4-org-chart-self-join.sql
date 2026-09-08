/*=============================================================================
  Topic 06 — Joins & APPLY
  P4 — Org Chart Self-Join                                          (Medium)
  -----------------------------------------------------------------------------
  Tags: self-join | left-join | aggregation

  PROBLEM
  -------
  1. Roster       Every user with their manager's name and job title. Users
                  with no manager appear as '(top level)'. Verify the count.

  2. Skip-level   Every user with manager AND skip-level manager. Three
                  app.Users aliases.

  3. Span of      Every manager with their direct-report count, descending.
     control      Only users who actually manage somebody.

  4. Bench        Users who are neither a manager nor assigned to any task.
     report       Use anti-joins (NOT EXISTS).

  5. Peer pairs   All pairs of users sharing the same manager, with no
                  self-pairs and no mirror duplicates.

  6. Write-up     Why a self-join can only walk a FIXED number of levels, and
                  what construct handles arbitrary depth.

  NOTES
  -----
  - app.Users.FullName is a persisted computed column. Use it; do not
    re-concatenate FirstName + LastName.
  - Only 7 users have any direct reports.
  - Requirement 5 needs b.UserId > a.UserId on the join.

  EXPECTED
  --------
  Query 1 = 20 rows (an INNER JOIN version would return 18 — note this).
  Query 3 = 7 rows, Linus Torvalds 4, Ada Lovelace 2.
  Query 5 = state the row count and justify it.
=============================================================================*/

USE TaskFlowDb;
GO

-------------------------------------------------------------------------------
-- 1. Roster: employee -> manager
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 2. Skip-level: employee -> manager -> manager's manager
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 3. Span of control: direct-report counts
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 4. Bench report: not a manager AND not assigned to any task
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 5. Peer pairs: same manager, no self-pairs, no mirrors
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 6. Write-up: fixed depth vs arbitrary depth
-------------------------------------------------------------------------------

-- TODO: your solution here
