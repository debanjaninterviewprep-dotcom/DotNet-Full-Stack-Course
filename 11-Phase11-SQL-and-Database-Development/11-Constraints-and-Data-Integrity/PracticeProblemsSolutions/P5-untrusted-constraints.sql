/*
    P5 -- Untrusted Constraints and the Optimizer  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. Actual plan for Tasks JOIN Projects -- record which tables the plan touches.
    2. ALTER TABLE app.Tasks NOCHECK CONSTRAINT FK_Tasks_Project -- re-run, record plan change,
       name the mechanism.
    3. Restore trust with WITH CHECK CHECK CONSTRAINT -- confirm is_disabled = 0 AND is_not_trusted = 0.
    4. Show ALTER TABLE ... CHECK CONSTRAINT ... (no WITH CHECK) re-enables but leaves untrusted.
       Prove from sys.foreign_keys and the plan.
    5. Repeat for a CHECK constraint (CK_TimeEntries_Hours) -- compare trusted vs untrusted plans.
    6. Add a FK WITH NOCHECK on a scratch table containing a violating row. Show it's created,
       the bad row survives, a NEW violation is still rejected. Explain enforced/trusted/disabled.
    7. Write the deployment health-check query (all untrusted/disabled constraints). State what
       CI should do with a non-empty result.
    8. Restore every constraint to trusted; prove the health-check query returns 0 rows.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
