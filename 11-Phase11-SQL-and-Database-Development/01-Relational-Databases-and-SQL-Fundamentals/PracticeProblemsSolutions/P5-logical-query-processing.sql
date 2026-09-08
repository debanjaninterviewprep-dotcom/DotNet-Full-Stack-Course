/*=============================================================================
  P5 — Logical Query Processing Detective                       (Medium)
  Topic 01: Relational Databases & SQL Fundamentals
  -----------------------------------------------------------------------------
  Tags: logical-query-processing | alias-scope | on-vs-where | having |
        top-order-by

  PROBLEM
  -------
  Four queries below are broken or misleading. For each: state the error number
  or wrong behaviour, name the LOGICAL PROCESSING STEP that explains it, and
  write the corrected query.

  -- BUG 1
  SELECT p.ProjectName, COUNT(*) AS TaskCount
  FROM app.Projects AS p
  JOIN app.Tasks    AS t ON t.ProjectId = p.ProjectId
  WHERE TaskCount > 3
  GROUP BY p.ProjectName;

  -- BUG 2  (intent: every project, plus its Done tasks)
  SELECT p.ProjectCode, t.Title
  FROM app.Projects AS p
  LEFT JOIN app.Tasks AS t ON t.ProjectId = p.ProjectId
  WHERE t.StatusId = 6;

  -- BUG 3  (intent: the 5 most overdue OPEN tasks)
  SELECT TOP (5) t.TaskId, t.Title, t.DueDate
  FROM app.Tasks AS t
  WHERE t.DueDate < '2025-09-01';

  -- BUG 4  (intent: users and how many tasks they created, only prolific ones)
  SELECT u.Email, COUNT(t.TaskId) AS Created
  FROM app.Users AS u
  LEFT JOIN app.Tasks AS t ON t.CreatedByUserId = u.UserId
  GROUP BY u.Email
  HAVING COUNT(t.TaskId) > 0
  ORDER BY Created DESC;
  -- Why does this return fewer rows than app.Users has, and is that correct?

  Then:
  5. Write the full logical processing order as a comment, and annotate a query
     of your own with the step number at which each clause is evaluated.
  6. Demonstrate that ORDER BY CAN see a SELECT alias while WHERE and GROUP BY
     cannot, using three short queries (two of which fail -- capture the message
     numbers).

  DELIVERABLE
  -----------
  This file, with every query run and its output pasted underneath as a comment.

  HINTS
  -----
  - Bug 1 is Msg 207. Bug 2 is not an error at all -- that is what makes it
    dangerous.
  - Bug 3 has two problems: non-determinism, and it ignores whether the task is
    still open.
  - For bug 4, HAVING COUNT(t.TaskId) > 0 cancels the LEFT JOIN. Decide whether
    that is the intent.
  - SQL Server also allows GROUP BY on an expression but not on its alias --
    worth demonstrating.
=============================================================================*/

USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  BUG 1 — diagnosis, offending step, and the fix
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  BUG 2 — diagnosis, offending step, and the fix
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  BUG 3 — diagnosis, offending step, and the fix
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  BUG 4 — analysis: why fewer rows than app.Users, and is that the intent?
          Give BOTH readings and the query for each.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 5 — Full logical processing order + an annotated query of your own
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 6 — Alias scope: ORDER BY sees it, WHERE and GROUP BY do not
           (capture the two message numbers)
-----------------------------------------------------------------------------*/
-- TODO: your solution here
