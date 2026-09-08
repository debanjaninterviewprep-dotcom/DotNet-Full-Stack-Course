/*=============================================================================
  Topic 06 — Joins & APPLY
  P3 — ON vs WHERE, Proven                                          (Medium)
  -----------------------------------------------------------------------------
  Tags: on-vs-where | left-join | null-semantics

  PROBLEM
  -------
  Scope everything to project 8 (TF-DS, tasks 31 / 32 / 33). Write four
  variants of the same query — TaskId plus assignee name — and record the
  exact result set of each:

      V1   no predicate            baseline LEFT JOIN chain
      V2   u.CountryCode = 'GB'    in the ON of the join to app.Users
      V3   u.CountryCode = 'GB'    in WHERE
      V4   u.CountryCode = 'US'    in the ON

  Then:

      5. A fifth variant that starts LEFT JOIN app.TaskAssignments but uses
         INNER JOIN app.Users. Explain why it behaves like V3 even though
         nothing moved into WHERE.

      6. A two-column comment table: "if the requirement is X, put the
         predicate in Y", covering at least four requirements.

  BACKGROUND
  ----------
  Tim Berners-Lee (UserId 14) is the only assignee in project 8 and his
  CountryCode is 'GB'. Task 33 is unassigned.

  EXPECTED
  --------
  V1 = 3 rows | V2 = 3 rows | V3 = 2 ROWS | V4 = 3 rows, all assignees NULL
=============================================================================*/

USE TaskFlowDb;
GO

-------------------------------------------------------------------------------
-- V1: baseline
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- V2: predicate in ON  ('GB')
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- V3: predicate in WHERE  ('GB')  -- the silent downgrade to INNER JOIN
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- V4: non-matching predicate in ON  ('US')
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- V5: LEFT JOIN followed by INNER JOIN — the broken outer chain
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Decision table (comment): requirement -> ON or WHERE
-------------------------------------------------------------------------------

-- TODO: your solution here
