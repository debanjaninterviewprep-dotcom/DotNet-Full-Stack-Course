/*
    P6 -- Full Diagnostic Narrative: Reproduce and Resolve a Regression  (Hard)
    See ../Practice-Problems.md for full requirements.
    Clean up all scratch objects at the end.

    WRITTEN DIAGNOSTIC REPORT (fill in as you complete each step -- mirrors Notes.md Sec 10):
    1. Symptom:
    2. Culprit query identification:
    3. Plan comparison (before vs after):
    4. Wait-stats correlation:
    5. Hypothesis:
    6. Tested fix:
    7. Verification under a repeated/looped workload:

    Using the synthetic large table from Topic 13 (recreate if needed):
    - Deliberately induce a plan regression (stale statistics after a large data change,
      or a competing index that confuses the choice).
    - Apply the fix; demonstrate return to original performance with before/after numbers
      for at least two metrics (e.g. logical reads, elapsed time).
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
