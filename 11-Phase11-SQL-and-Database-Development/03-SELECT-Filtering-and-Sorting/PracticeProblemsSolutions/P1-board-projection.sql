/*=============================================================================
  Topic 03 — SELECT, Filtering & Sorting
  P1 — The Task Board Projection                                      (Easy)
  -----------------------------------------------------------------------------
  Tags: select, projection, aliases, table-aliases, select-star

  PROBLEM
  The TaskFlow web client calls GET /api/board. The front-end DTO is:

      interface BoardCard {
        taskId: number;
        title: string;
        projectCode: string;
        statusName: string;
        priorityName: string;
        dueDate: string | null;
      }

  REQUIREMENTS
    1. Write one SELECT that returns EXACTLY those six columns, in that order,
       aliased to match the DTO property names:
       TaskId, Title, ProjectCode, StatusName, PriorityName, DueDate.
    2. Source from app.Tasks, app.Projects, ref.TaskStatuses and ref.Priorities.
    3. Alias every table with a short alias and QUALIFY EVERY COLUMN.
    4. Write the query twice: once with `expr AS alias`, once with the T-SQL
       `alias = expr` form. Comment on which you would commit, and why.
    5. Add a final commented-out SELECT * version and list THREE concrete
       failures that would occur if it shipped.

  HINTS
    - ref.TaskStatuses joins on StatusId; ref.Priorities joins on PriorityId.
    - app.Tasks.DueDate is already DATE — no conversion needed.
    - The DTO has no Description; app.Tasks.Description is NVARCHAR(MAX).
      That is one of your three failures.
=============================================================================*/

USE TaskFlowDb;
GO

-----------------------------------------------------------------------------
-- 1. Projection using `expr AS alias`
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 2. The same projection using the T-SQL `alias = expr` form
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 3. Which form would you commit to the repository, and why?
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- 4. The SELECT * version (COMMENTED OUT) + three concrete failure modes
-----------------------------------------------------------------------------

-- TODO: your solution here
GO
