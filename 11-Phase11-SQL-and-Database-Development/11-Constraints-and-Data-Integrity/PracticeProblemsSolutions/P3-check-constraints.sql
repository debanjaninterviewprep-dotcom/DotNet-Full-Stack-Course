/*
    P3 -- Domain Integrity with CHECK  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. Add CK_Tasks_StoryPoints: StoryPoints IN (1,2,3,5,8,13,21), NULL allowed. WITH CHECK.
       Verify is_not_trusted = 0.
    2. Add CK_Tasks_CompletionConsistency: CompletedAtUtc non-NULL only if StatusId IN (6,7).
    3. Attempt the CONVERSE (every terminal task must have CompletedAtUtc) -- must fail.
       Capture the error; find the offending rows; explain the business situation.
    4. NULL trap demo: CHECK (col > 0) vs CHECK (col IS NULL OR col > 0) -- prove identical;
       give the strict version.
    5. Collation trap: CHECK (CountryCode LIKE '[A-Z][A-Z]') accepts 'gb' by default --
       fix with COLLATE Latin1_General_BIN2.
    6. Attempt a CHECK containing a subquery -- capture the error number/message.
    7. Explain why a scalar UDF doing the same subquery is worse than no constraint (>= 3 failure modes).
    8. Drop every constraint added; confirm check-constraint count is back to 6.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
