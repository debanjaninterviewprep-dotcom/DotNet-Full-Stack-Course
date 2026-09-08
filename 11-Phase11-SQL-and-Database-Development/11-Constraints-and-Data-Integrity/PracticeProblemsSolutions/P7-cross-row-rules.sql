/*
    P7 -- Rules a CHECK Cannot Express  (Hard)
    See ../Practice-Problems.md for full requirements.

    1. "At most one primary assignee per task": filtered unique index on app.TaskAssignments.
       Prove it creates, then prove it blocks a second primary on task 4. State the error number.
    2. "Logged hours must not exceed 2x estimate": AFTER INSERT, UPDATE trigger on
       app.TimeEntries, rolling back via THROW. Test against task 1 (est 24.00, logged 18.75).
    3. "A project's tasks must belong to the project team's members": decide trigger vs
       application vs nowhere -- justify in a comment. Implement or explain why not.
    4. Comment table per rule: mechanism / INSERT? / UPDATE? / DELETE? / concurrency-safe? / cost.
    5. Show rule 2 done with a scalar UDF in a CHECK failing: construct a DELETE that breaks
       the invariant while the constraint stays happy.
    6. Explain how an indexed view would also solve rule 2 (WITH SCHEMABINDING, COUNT_BIG(*)) --
       which would you ship?
    7. Drop the index, trigger, function, everything -- confirm database is back to seeded state.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
