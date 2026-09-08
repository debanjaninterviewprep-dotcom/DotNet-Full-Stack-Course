/*
    P5 -- Views for Column and Row Security  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. app.vw_UserDirectory: every app.Users column EXCEPT HourlyRate.
    2. Explain exactly when this provides real security vs none (base-table permissions).
    3. app.vw_MyDirectReports via SESSION_CONTEXT -- test with Grace Hopper's UserId (2),
       confirm result = Linus Torvalds (4) + Margaret Hamilton (5).
    4. Explain why Row-Level Security (name it) is more robust than this view pattern.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
