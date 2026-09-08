/*
    P8 -- Integrity Design Review: TaskFlow Sprints -- Runnable DDL  (Hard)
    See ../Practice-Problems.md for the full 14-rule requirement list, and
    ./P8-integrity-review.md for the written design review this DDL implements.

    15. Complete, runnable CREATE TABLE DDL for app.Sprints and app.SprintTasks with every
        declarative rule implemented and every constraint named per TaskFlow convention.
    16. DDL for every non-declarative mechanism chosen (indexes, triggers).
    17. PRINT-based smoke test proving at least four rules actually fire.
    18. (Portability section lives in the .md file.)
    19. Rollback script that drops everything created here.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here

-- ============================================================================
-- Rollback (run to remove everything this script created)
-- ============================================================================
-- TODO: DROP every object created above, in dependency order.
