/*=============================================================================
  P4 — Relational Algebra to T-SQL                              (Medium)
  Topic 01: Relational Databases & SQL Fundamentals
  -----------------------------------------------------------------------------
  Tags: relational-algebra | set-operators | joins | division

  PROBLEM
  -------
  Implement each operator against TaskFlow. One query per operator, each
  preceded by a comment naming the algebraic form.

  1. Selection + Projection -- task id and title of all CRITICAL priority tasks,
     WITHOUT hard-coding PriorityId = 1.
  2. Cartesian product -- every status/priority pair. State the expected row
     count BEFORE you run it.
  3. Union -- all task titles that are either BLOCKED or IN_REVIEW, using a set
     operator (not OR). Then show the UNION vs UNION ALL difference and explain
     which is correct here.
  4. Intersection -- users who are both a team lead (app.Teams.LeadUserId) AND a
     project owner (app.Projects.OwnerUserId).
  5. Difference -- labels defined in app.Labels but never applied in
     app.TaskLabels. Then write the same result with NOT EXISTS and compare the
     two execution plans.
  6. Outer join -- every project with its task count, INCLUDING projects with
     zero tasks. Explain why COUNT(*) is wrong here and what to use instead.
  7. Division -- every user assigned to EVERY task in project 'TF-SEC'. Use the
     double-NOT EXISTS pattern.
  8. Aggregation -- total billable hours per project, with projects that have no
     time entries showing 0.00 rather than NULL.

  DELIVERABLE
  -----------
  This file, with every query run and its output pasted underneath as a comment.

  HINTS
  -----
  - For 1, join ref.Priorities and filter on PriorityCode = 'CRITICAL'.
  - For 2, CROSS JOIN; 7 statuses times 5 priorities.
  - For 6, COUNT(*) counts the outer-join placeholder row and returns 1 instead
    of 0. Count a column from the INNER side.
  - For 8, SUM over an empty set is NULL; wrap with COALESCE(..., 0) and
    remember IsBillable = 1.
  - Division is "there is no task in TF-SEC for which this user has no
    assignment".
=============================================================================*/

USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  1. Selection + Projection      pi(TaskId, Title)( sigma(PriorityCode='CRITICAL') )
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  2. Cartesian product           TaskStatuses x Priorities
     Expected row count before running: ____
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  3. Union                       BLOCKED titles UNION IN_REVIEW titles
     Also show UNION vs UNION ALL and justify the choice.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  4. Intersection                team leads INTERSECT project owners
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  5. Difference                  Labels EXCEPT TaskLabels
     Then the NOT EXISTS equivalent + a plan comparison.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  6. Outer join                  every project + task count, zeros included
     Why is COUNT(*) wrong here?
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  7. Division                    users assigned to EVERY task in 'TF-SEC'
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  8. Aggregation                 billable hours per project, empty groups = 0.00
-----------------------------------------------------------------------------*/
-- TODO: your solution here
