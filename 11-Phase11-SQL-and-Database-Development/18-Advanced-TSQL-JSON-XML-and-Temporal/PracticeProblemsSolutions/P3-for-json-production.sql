/*
    P3 -- Producing JSON with FOR JSON  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. Project + tasks (joined), FOR JSON AUTO -- observe the inferred nesting.
    2. Same requirement via FOR JSON PATH with dotted aliases -- deliberately different,
       more API-appropriate nesting (tasks as an array under the project).
    3. Single-object (WITHOUT_ARRAY_WRAPPER) payload for one task, including its primary
       assignee's name/email nested under an "Assignee" key.
    4. Explain one concrete scenario where AUTO's inferred nesting silently produces the
       wrong shape for an API contract.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
