/*
    P6 — Recursive CTE: Full Org Chart with Depth and Path  (Hard)
    See ../Practice-Problems.md for full requirements.

    1. Recursive CTE over app.Users/ManagerId: every employee with Depth and a human-readable
       Chain (e.g. "Ada Lovelace > Alan Turing > Barbara Liskov").
    2. Add a zero-padded SortPath column; order by it so the tree renders indented correctly.
    3. Cap the recursion with an explicit, justified MAXRECURSION value (not 0).
    4. Modify the anchor to produce only the subtree under Grace Hopper (UserId 2) -- expect 12 rows.
    5. Walk UPWARD from Hedy Lamarr (UserId 16) to the root -- note which single change
       (anchor or join direction) made that possible.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
