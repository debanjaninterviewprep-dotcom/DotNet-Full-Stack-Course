/*
    P2 — IN, ANY, ALL and the Empty-Set Rules  (Easy)
    See ../Practice-Problems.md for full requirements.

    1. Tasks in any project owned by Margaret Hamilton (UserId 5), using IN.
    2. Same query rewritten with = ANY.
    3. > ALL against project 5's estimates, once unguarded (NULLs included) and once guarded
       (EstimatedHours IS NOT NULL) -- compare row counts and explain the difference.
    4. One query each for IN / NOT IN / = ANY / > ALL / EXISTS / NOT EXISTS against an empty
       subquery -- predict the boolean result in a comment, then verify.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
