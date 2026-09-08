/*
    P1 -- Reading and Modifying JSON  (Easy)
    See ../Practice-Problems.md for full requirements.
    Wrap the data change in a transaction you roll back.

    1. List tasks with non-NULL MetadataJson + JSON_VALUE(..., '$.epic') where present.
    2. Task 1: JSON_QUERY the 'reviewers' array; show JSON_VALUE on the same path returns
       NULL -- explain why.
    3. JSON_MODIFY: add "risk_reviewed": true to task 4's MetadataJson without destroying
       existing keys; verify.
    4. JSON_MODIFY again to remove that key (set to NULL); confirm original shape restored.
    5. Roll back.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
