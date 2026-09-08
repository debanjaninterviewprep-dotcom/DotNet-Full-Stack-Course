/*=============================================================================
  Topic 04 — Built-In Functions & Expressions
  P3 — Date Arithmetic Done Right                                   (Medium)
  -----------------------------------------------------------------------------
  Tags: dateadd, datediff, datediff-big, eomonth, datepart, datename, age

  REQUIREMENTS
    1. Demonstrate that DATEDIFF counts BOUNDARY CROSSINGS, not elapsed units,
       with three separate one-line proofs (YEAR, MONTH, HOUR).
    2. Trigger Msg 535 with DATEDIFF(MILLISECOND, ...) over the span from the
       earliest app.Tasks.CreatedAtUtc to now. Record the error verbatim, then
       fix it with DATEDIFF_BIG.
    3. Build a table in comments listing the approximate overflow threshold for
       SECOND, MILLISECOND, MICROSECOND and NANOSECOND.
    4. Compute, for each project, the number of WHOLE MONTHS it has been
       running — correctly, not DATEDIFF(MONTH, ...).
    5. Compute a correct "age in whole years" for an arbitrary @Dob / @Today.
       Prove it with a case where naive DATEDIFF(YEAR, ...) is off by one.
    6. For each task with a due date, show DATEPART(QUARTER), DATEPART(ISO_WEEK),
       DATENAME(MONTH) and DATENAME(WEEKDAY). Then SET LANGUAGE French; and
       re-run. Explain what changed and what that means for storing or filtering
       on DATENAME output.
    7. Show three ways to truncate CreatedAtUtc to the first of its month:
       DATEFROMPARTS, the DATEADD/DATEDIFF anchor idiom, and DATETRUNC.
       Note the version requirement for the third.
    8. Use EOMONTH to produce, per task, the month end and the previous month
       end of the due date.

  HINTS
    - The earliest CreatedAtUtc is in February 2024 — far past the ~24.8-day
      millisecond limit.
    - Correct age idiom:
        DATEDIFF(YEAR, dob, today)
          - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, dob, today), dob) > today
                 THEN 1 ELSE 0 END
    - SET LANGUAGE also changes @@DATEFIRST. Reset with SET LANGUAGE us_english;
    - DATETRUNC requires SQL Server 2022 / Azure SQL. Guard or comment it out.

  CLEANUP: restore the session language before the script ends.
=============================================================================*/

USE TaskFlowDb;
GO

-----------------------------------------------------------------------------
-- 1. DATEDIFF counts boundary crossings — three proofs (YEAR, MONTH, HOUR)
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 2a. Trigger Msg 535 with DATEDIFF(MILLISECOND, ...). Record it verbatim.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 2b. Fix it with DATEDIFF_BIG
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 3. Overflow threshold table (comment block)
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- 4. Whole months running, per project — done correctly
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 5. Age in whole years, with a demonstrated off-by-one for the naive version
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 6a. DATEPART(QUARTER / ISO_WEEK) + DATENAME(MONTH / WEEKDAY) — default language
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 6b. Same query under SET LANGUAGE French. What changed, and what does that
--     mean for storing or filtering on DATENAME output?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 7. Three ways to truncate to the first of the month
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 8. EOMONTH: month end and previous month end of the due date
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- CLEANUP — restore the session language
-----------------------------------------------------------------------------
SET LANGUAGE us_english;
GO
