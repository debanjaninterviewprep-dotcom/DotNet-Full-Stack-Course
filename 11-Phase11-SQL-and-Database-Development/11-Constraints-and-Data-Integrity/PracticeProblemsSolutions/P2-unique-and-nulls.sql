/*
    P2 -- The One-NULL Rule  (Easy)
    See ../Practice-Problems.md for full requirements.

    1. Create app.ProjectExternalRefs (ProjectId PK/FK, JiraKey VARCHAR(20) NULL UNIQUE).
    2. Insert one real key, one NULL, then a second NULL -- capture the error verbatim.
    3. Insert a duplicate non-NULL key -- capture that error and its number.
    4. Drop the UNIQUE constraint; replace with a filtered unique index WHERE JiraKey IS NOT NULL.
    5. Repeat steps 2-3 -- note which now succeed, and the DIFFERENT error number.
    6. Query sys.indexes: is_unique, is_unique_constraint, has_filter, filter_definition (before/after).
    7. Comment table comparing UNIQUE constraint vs unique index across >= 5 dimensions.
    8. Drop the table.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
