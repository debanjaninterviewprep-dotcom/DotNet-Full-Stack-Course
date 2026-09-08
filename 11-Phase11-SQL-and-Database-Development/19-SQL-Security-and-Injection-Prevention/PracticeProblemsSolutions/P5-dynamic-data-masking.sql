/*
    P5 -- Dynamic Data Masking  (Medium)
    See ../Practice-Problems.md for full requirements.
    Remove masking and any test user at the end; leave the real schema unchanged.

    1. Mask app.Users.Email (email() function) and app.Users.HourlyRate (random() range).
    2. Query as owner/admin (implicit UNMASK) -- confirm real values visible.
    3. Test user with only SELECT (no UNMASK) -- via EXECUTE AS USER, confirm masked values.
    4. Demonstrate the limitation: as the masked user, SELECT COUNT(*) FROM app.Users
       WHERE HourlyRate > 100 still filters correctly against the REAL value.
    5. Remove masking; drop the test user; leave the real schema unchanged.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
