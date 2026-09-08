/*
    P1 -- Constraint Inventory  (Easy)
    See ../Practice-Problems.md for full requirements.

    1. Every PK/UNIQUE constraint (table, constraint name, type_desc) -- count each.
    2. Every FK (child table, parent table, delete/update referential action) -- count total
       and how many use CASCADE.
    3. Every FK column pair in key order (sys.foreign_key_columns) -- identify composite FKs.
    4. Every CHECK constraint with its definition text.
    5. Every DEFAULT constraint with its column and definition text.
    6. Every nullable column in the app schema -- name the 3 whose NULL has documented meaning.
    7. Two "should be empty" audits: tables with no PK; disabled/untrusted constraints.
    8. Repeat 1-2 using INFORMATION_SCHEMA -- note 3 things it cannot tell you.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
