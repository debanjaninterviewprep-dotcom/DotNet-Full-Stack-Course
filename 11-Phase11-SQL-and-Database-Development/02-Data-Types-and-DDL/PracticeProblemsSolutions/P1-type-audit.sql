/*=============================================================================
  P1 — Type Audit of TaskFlowDb                                 (Easy)
  Topic 02: Data Types & DDL
  -----------------------------------------------------------------------------
  Tags: catalog-views | choosing-types | deprecated-types | storage-math

  PROBLEM
  -------
  1. Write ONE query returning every column in the app, ref and audit schemas
     with: schema, table, column, type name, max_length, precision, scale,
     is_nullable, is_identity, is_computed, and the collation.
  2. Produce a DEPRECATED-TYPE SCAN for TEXT, NTEXT and IMAGE. State the result
     and the modern replacement for each.
  3. Compute the THEORETICAL MAXIMUM ROW WIDTH IN BYTES for app.Tasks, ignoring
     the NVARCHAR(MAX) columns. Show your arithmetic. Then state how many such
     rows fit in one 8 KB page.
  4. For each of these columns, write one line justifying the chosen type -- or
     arguing it is wrong:
       ref.TaskStatuses.StatusId, app.Users.HourlyRate, app.Users.CountryCode,
       app.Labels.ColorHex, app.Tasks.StoryPoints, app.Tasks.CreatedAtUtc,
       app.Projects.StartDate, audit.TaskHistory.TaskHistoryId,
       audit.TaskHistory.ChangedBy.
  5. Find every column whose declared length is MORE THAN FOUR TIMES the longest
     value actually stored, using the shipped data. Report the wasted width.
  6. audit.TaskHistory.ChangedBy is SYSNAME. State what SYSNAME actually is and
     why SQL Server uses it for identifiers.

  DELIVERABLE
  -----------
  This file, with every query run and its output pasted underneath as a comment.

  HINTS
  -----
  - sys.columns joined to sys.types on user_type_id, or TYPE_NAME(c.user_type_id).
  - max_length is in BYTES: NVARCHAR(200) reports 400, and MAX reports -1.
  - Row width: TINYINT 1, INT 4, BIGINT 8, DATE 3, DATETIME2(3) 7,
    DECIMAL(6,2) 5, plus 2 bytes of offset per variable-length column.
  - Roughly 8,060 bytes per page are usable for row data.
  - MAX(DATALENGTH(col)) gives real bytes; MAX(LEN(col)) gives characters.
=============================================================================*/

USE TaskFlowDb;
GO

/*-----------------------------------------------------------------------------
  Step 1 — Full column inventory for app / ref / audit (ONE query)
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 2 — Deprecated-type scan (TEXT / NTEXT / IMAGE) + replacements
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 3 — Maximum row width for app.Tasks, and rows per 8 KB page.
           Show the arithmetic, column by column.
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 4 — One line justifying (or challenging) each of the nine column types
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 5 — Over-declared columns: declared width > 4x the longest stored value
-----------------------------------------------------------------------------*/
-- TODO: your solution here


/*-----------------------------------------------------------------------------
  Step 6 — What is SYSNAME, and why does SQL Server use it?
-----------------------------------------------------------------------------*/
-- TODO: your solution here
