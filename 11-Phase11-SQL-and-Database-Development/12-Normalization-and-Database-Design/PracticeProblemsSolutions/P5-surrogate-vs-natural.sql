/*
    P5 -- Surrogate vs Natural Key Decision Table (DDL part)  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. For app.Users, app.Projects, ref.TaskStatuses: identify natural key(s), the chosen
       surrogate key, and the constraint preserving the natural key as an alternate key.
    2. Explain (comment) why sequential IDENTITY beats random UNIQUEIDENTIFIER as a clustering
       key, referencing fragmentation; name the mitigation feature.
    3. Design app.ApiKeys DDL where a globally-unique, non-sequential identifier is the RIGHT
       choice -- justify why this case differs from app.Tasks.
    4. (Decision table lives in P5-key-decision-table.md)
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
