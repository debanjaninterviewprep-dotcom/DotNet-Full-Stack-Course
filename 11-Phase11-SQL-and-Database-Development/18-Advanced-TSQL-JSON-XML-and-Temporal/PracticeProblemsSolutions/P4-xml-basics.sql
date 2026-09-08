/*
    P4 -- XML Basics: .value(), .exist(), .nodes()  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. XML variable with >= 3 <Task> elements (id attribute + Title/Priority children).
    2. .value(): extract the SECOND task's Title by position.
    3. .exist(): check a present id (1) and an absent id (0).
    4. .nodes() + CROSS APPLY: shred the whole variable into TaskId/Title/Priority columns.
    5. .modify(): change one task's Priority in place; verify with a follow-up .value() call.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
