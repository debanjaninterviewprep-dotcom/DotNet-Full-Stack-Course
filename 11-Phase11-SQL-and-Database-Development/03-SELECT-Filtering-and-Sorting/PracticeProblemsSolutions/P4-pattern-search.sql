/*=============================================================================
  Topic 03 — SELECT, Filtering & Sorting
  P4 — Pattern Search Across Titles and Metadata                    (Medium)
  -----------------------------------------------------------------------------
  Tags: like, wildcards, escape, character-classes, collation, sargability

  PROBLEM
  Build the search predicates behind TaskFlow's quick-search box. Write one
  query per bullet, each labelled with a comment.

  REQUIREMENTS
    1. Tasks whose Title STARTS WITH 'Fix'.
    2. Tasks whose Title CONTAINS any digit, using a character class.
    3. Tasks whose Title contains NO digit, using a negated character class.
       Explain why the naive negated pattern does not mean what most people think.
    4. Comments in app.Comments whose Body contains a LITERAL percent sign.
       Write it twice — once with ESCAPE, once with a character class.
    5. Tasks whose MetadataJson contains a snake_case key (a literal underscore).
    6. A case-SENSITIVE search for 'fix' at the start of Title using an explicit
       COLLATE. Explain what this costs.
    7. For each of the six predicates, mark whether it is SEEKABLE or SCAN-ONLY,
       and why.

  HINTS
    - The comment on task 25 contains the text 'above 5% flake rate'.
    - N'%[_]%' and N'%!_%' ESCAPE '!' are equivalent.
    - LIKE N'%[^0-9]%' means "contains at least one non-digit" — NOT "contains
      no digits". You need NOT LIKE N'%[0-9]%'.
    - COLLATE on the left-hand side of a predicate makes it non-SARGable.
=============================================================================*/

USE TaskFlowDb;
GO

-----------------------------------------------------------------------------
-- 1. Title starts with 'Fix'
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 2. Title contains any digit (character class)
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 3. Title contains NO digit.
--    Also: why does LIKE N'%[^0-9]%' not mean what people expect?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 4a. Comment Body contains a literal '%' — using ESCAPE
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 4b. Same result — using a character class instead of ESCAPE
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 5. MetadataJson contains a snake_case key (literal underscore)
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 6. Case-SENSITIVE prefix search using COLLATE. What does it cost?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 7. SARGability table: for each predicate above, SEEKABLE or SCAN-ONLY, and why.
--    Name at least one real alternative for '%contains%' search at scale.
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)
GO
