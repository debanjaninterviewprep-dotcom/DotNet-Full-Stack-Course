/*=============================================================================
  P8 — Workload Fit: OLTP, OLAP & the Storage Decision          (Hard)
  Topic 01: Relational Databases & SQL Fundamentals
  -----------------------------------------------------------------------------
  Tags: oltp-olap | sql-vs-nosql | architecture | engine-architecture

  PROBLEM
  -------
  You are the engineer arguing TaskFlow's data architecture in a design review.

  1. Classify EIGHT real TaskFlow queries as OLTP or OLAP, with a one-line
     justification each. At least three must be genuinely ambiguous. Write and
     run all eight. Suggested set:
       a. Move a task to IN_REVIEW.
       b. The Kanban board for project 'TF-CORE'.
       c. Average cycle time (CreatedAtUtc -> CompletedAtUtc) per team per quarter.
       d. A user's assigned open tasks.
       e. Total billable hours per project per month.
       f. Label co-occurrence counts.
       g. The audit trail for one task.
       h. Count of overdue tasks by priority across all projects.
  2. Using sys.dm_exec_query_stats or SET STATISTICS IO ON, capture LOGICAL
     READS for your most OLTP-ish and most OLAP-ish query. Report the ratio and
     explain it in terms of PAGES, not rows.
  3. Build a DECISION MEMO (comments, 300-500 words): at what point does
     TaskFlow need a separate analytical store? Define a concrete trigger
     metric, not a feeling.
  4. Fill in a SQL vs NoSQL decision table for three subsystems: the core task
     graph, real-time presence ("who is viewing this task"), and the activity
     feed. Recommend a store for each and state what you give up.
  5. app.Tasks.MetadataJson is a document embedded in a relational table. Argue
     both sides: when this is pragmatic, and the specific point at which it
     becomes technical debt. Reference at least one concrete painful query.
  6. Sketch (comment block) the star schema for question 1c: name the fact
     table, its GRAIN, its measures, and three dimensions.

  DELIVERABLE
  -----------
  This file, with every query run and its output pasted underneath as a comment.

  HINTS
  -----
  - Cycle time: DATEDIFF(HOUR, t.CreatedAtUtc, t.CompletedAtUtc) over rows where
    CompletedAtUtc IS NOT NULL, joined through app.Projects to app.Teams.
  - Label co-occurrence is a self-join of app.TaskLabels on TaskId with
    l1.LabelId < l2.LabelId.
  - Logical reads are 8 KB pages. A query reading 4,000 pages touched 32 MB of
    buffer pool regardless of how many rows it returned.
  - A good trigger metric looks like: "p95 board-load latency exceeds 300 ms
    while the reporting workload is running" -- measurable, attributable,
    falsifiable.
  - Grain is the most important line in the star-schema sketch. State it as
    "one row per ___".
=============================================================================*/

USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  Step 1 — Eight queries, each classified OLTP or OLAP with a justification
-----------------------------------------------------------------------------*/
-- 1a. Move a task to IN_REVIEW.                          Classification: ____
-- TODO: your solution here


-- 1b. Kanban board for project 'TF-CORE'.                Classification: ____
-- TODO: your solution here


-- 1c. Average cycle time per team per quarter.           Classification: ____
-- TODO: your solution here


-- 1d. A user's assigned open tasks.                      Classification: ____
-- TODO: your solution here


-- 1e. Total billable hours per project per month.        Classification: ____
-- TODO: your solution here


-- 1f. Label co-occurrence counts.                        Classification: ____
-- TODO: your solution here


-- 1g. The audit trail for one task.                      Classification: ____
-- TODO: your solution here


-- 1h. Overdue tasks by priority, all projects.           Classification: ____
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 2 — Logical reads for the most OLTP-ish vs most OLAP-ish query.
           Report the ratio and convert pages to MB.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 3 — Decision memo (300-500 words) with a concrete trigger metric
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4 — SQL vs NoSQL decision table for three subsystems
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 5 — MetadataJson: pragmatic escape hatch, or technical debt?
           Include the concrete painful query.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 6 — Star schema sketch: fact table, GRAIN, measures, three dimensions
-----------------------------------------------------------------------------*/
-- TODO: your solution here
