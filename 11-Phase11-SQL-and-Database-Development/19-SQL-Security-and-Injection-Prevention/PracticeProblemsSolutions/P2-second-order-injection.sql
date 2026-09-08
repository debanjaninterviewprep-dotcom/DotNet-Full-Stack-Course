/*
    P2 -- Second-Order Injection  (Medium)
    See ../Practice-Problems.md for full requirements.
    Wrap the data change in a transaction you roll back; drop any procedures created.

    1. PARAMETERISED (safe) INSERT storing a task title containing a SQL metacharacter
       payload (e.g. Fix bug'; SELECT * FROM app.Users; --) -- confirm stored as literal text.
    2. SEPARATE script reading it back and concatenating into a NEW dynamic SQL string
       (simulating a careless later report/export) -- demonstrate the payload now executes.
    3. Fix the second script with sp_executesql -- confirm the payload is inert again.
    4. Roll back; drop procedures.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
