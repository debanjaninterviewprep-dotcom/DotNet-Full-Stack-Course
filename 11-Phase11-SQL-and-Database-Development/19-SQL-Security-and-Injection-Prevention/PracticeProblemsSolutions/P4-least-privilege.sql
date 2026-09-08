/*
    P4 -- Least Privilege: Logins, Users, Roles  (Medium)
    See ../Practice-Problems.md for full requirements.
    Drop the test login/user, roles, and any procedures created solely for this exercise.

    1. role_taskflow_reader: SELECT only on app.vw_OpenTasks + app.vw_UserDirectory
       (create if needed) -- NO base table permission.
    2. role_taskflow_api: EXECUTE only on 2-3 designated procedures -- NO direct table permissions.
    3. Test login/user added to role_taskflow_reader -- demonstrate it can query the views
       but a direct SELECT * FROM app.Users fails with a permissions error.
    4. Explain why granting on the view protects HourlyRate even though the role has
       "read access to user data."
    5. Clean up everything created.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
