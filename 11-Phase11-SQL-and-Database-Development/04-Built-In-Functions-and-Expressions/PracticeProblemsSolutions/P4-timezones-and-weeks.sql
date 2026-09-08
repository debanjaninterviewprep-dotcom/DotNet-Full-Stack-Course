/*=============================================================================
  Topic 04 — Built-In Functions & Expressions
  P4 — Time Zones and Week Boundaries                               (Medium)
  -----------------------------------------------------------------------------
  Tags: at-time-zone, switchoffset, todatetimeoffset, datefirst, iso-week,
        sargability

  PROBLEM
  A TaskFlow bug report: "Due dates are one day off for our India team, and the
  weekly burndown starts on a different day depending on who runs it."

  REQUIREMENTS
    1. Query sys.time_zone_info for 'UTC', 'GMT Standard Time' and
       'India Standard Time'. Record the current offsets and DST flags.
    2. Show the WRONG conversion — a single AT TIME ZONE 'India Standard Time'
       applied directly to app.Tasks.CreatedAtUtc — and explain precisely what
       it did.
    3. Show the correct two-step AT TIME ZONE 'UTC' AT TIME ZONE '<target>' for
       both London and India, for at least three tasks.
    4. Demonstrate SWITCHOFFSET and TODATETIMEOFFSET and state, in one sentence
       each, how they differ from AT TIME ZONE.
    5. Explain why
         WHERE t.CreatedAtUtc AT TIME ZONE 'UTC' AT TIME ZONE 'India Standard Time' >= @local
       is a performance bug, and write the SARGable alternative.
    6. Show that DATEPART(WEEKDAY, '2025-08-30') returns different values under
       SET DATEFIRST 1 and SET DATEFIRST 7.
    7. Write a DATEFIRST-independent "start of the Monday week" expression TWICE
       — once with the 1900-01-01 anchor, once by neutralising @@DATEFIRST
       arithmetically — and prove both agree under at least two DATEFIRST settings.
    8. Show DATEPART(WEEK, ...) vs DATEPART(ISO_WEEK, ...) for the same date
       under two DATEFIRST settings, and state which one you would put in a report.
    9. Reset DATEFIRST at the end of the script.

  HINTS
    - AT TIME ZONE on a value with no offset ATTACHES; on a value with an offset
      it CONVERTS. That is the whole bug in requirement 2.
    - 1900-01-01 was a Monday, which is what makes
      DATEDIFF(DAY, '19000101', d) % 7 stable.
    - The arithmetic neutraliser is -((DATEPART(WEEKDAY, d) + @@DATEFIRST - 2) % 7).
    - ISO_WEEK follows ISO-8601 and ignores DATEFIRST entirely.

  CLEANUP: restore DATEFIRST before the script ends.
=============================================================================*/

USE TaskFlowDb;
GO

-----------------------------------------------------------------------------
-- 1. sys.time_zone_info for UTC, GMT Standard Time, India Standard Time
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 2. The WRONG conversion: a single AT TIME ZONE on a naive DATETIME2.
--    What exactly did it do?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 3. The CORRECT two-step conversion — London and India
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 4. SWITCHOFFSET and TODATETIMEOFFSET. How does each differ from AT TIME ZONE?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 5. Why is AT TIME ZONE in a WHERE clause a performance bug?
--    Write the SARGable alternative.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 6. DATEPART(WEEKDAY, ...) under SET DATEFIRST 1 vs SET DATEFIRST 7
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 7. Two DATEFIRST-independent "start of the Monday week" expressions.
--    Prove they agree under at least two DATEFIRST settings.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 8. DATEPART(WEEK) vs DATEPART(ISO_WEEK) under two DATEFIRST settings.
--    Which goes in the report, and why?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- CLEANUP — restore DATEFIRST
-----------------------------------------------------------------------------
SET DATEFIRST 7;
GO
