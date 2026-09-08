/*=============================================================================
  Topic 06 — Joins & APPLY
  P6 — Non-Equi Join: SLA Bands                                     (Medium)
  -----------------------------------------------------------------------------
  Tags: non-equi-join | range-join | nulls | cross-join

  PROBLEM
  -------
  1. Define an SLA band table inline with
         (VALUES ...) AS b (BandName, MinHours, MaxHours)
     Bands: 'Same day' [0,8), 'Next day' [8,24), 'This week' [24,168),
            'Backlog' [168,8760).

  2. Join ref.Priorities to the bands on a HALF-OPEN range. Report which band
     each of the 5 priorities lands in.

  3. Rewrite the predicate with BETWEEN MinHours AND MaxHours and show which
     priority now matches two bands. Explain why half-open intervals are
     mandatory.

  4. Explain what happens to the NONE priority (SlaHours is NULL) under
     INNER JOIN versus LEFT JOIN. Pick one and justify it.

  5. Roll the bands up to tasks: task count per band, including a row for
     tasks whose priority has no SLA. Verify the total is 35.

  6. Build a dense band x status grid with CROSS JOIN so every combination
     appears even with zero tasks. State the row count.

  7. Comment: why can a range join not use a Hash Match operator, and what
     does that imply for large band tables?

  EXPECTED
  --------
  2. CRITICAL -> Same day, HIGH -> This week, MEDIUM -> This week,
     LOW -> Backlog, NONE -> NULL.       (5 rows)
  3. HIGH duplicates; 6 rows instead of 5.
  5. Same day 4 | This week 23 | Backlog 5 | no band 3 = 35.
  6. row count must equal bands x statuses.
=============================================================================*/

USE TaskFlowDb;
GO

-------------------------------------------------------------------------------
-- 2. Half-open range join: priority -> band
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 3. The BETWEEN version and the duplicate it creates
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 4. INNER vs LEFT for the NULL-SLA priority, with justification
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 5. Task counts per band (total must be 35)
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 6. Dense band x status grid via CROSS JOIN
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 7. Comment: why no Hash Match on a range predicate
-------------------------------------------------------------------------------

-- TODO: your solution here
