/*=============================================================================
  Topic 04 — Built-In Functions & Expressions
  P1 — The String Toolkit                                             (Easy)
  -----------------------------------------------------------------------------
  Tags: string-functions, len-datalength, charindex, stuff, concat, concat-ws

  PROBLEM
  The TaskFlow audit export needs an anonymised user roster.

  REQUIREMENTS
    1. Show LEN vs DATALENGTH for app.Users.Email. Explain the exact ratio and
       why it is what it is. Then show a literal with trailing spaces where the
       two disagree for a DIFFERENT reason.
    2. Split each email into LocalPart and Domain using LEFT, RIGHT and CHARINDEX.
    3. Produce a MaskedEmail that keeps the first and last character of the local
       part and replaces the middle with exactly five asterisks, using STUFF and
       REPLICATE.
    4. Build an Initials column (e.g. 'AL' for Ada Lovelace).
    5. Build a display string three ways — '+', CONCAT and CONCAT_WS — combining
       FullName, JobTitle and CountryCode. Run all three, then explain by UserId
       exactly where they differ and why.
    6. Use TRANSLATE to strip '{', '}' and '"' from app.Tasks.MetadataJson, and
       write the equivalent nested REPLACE. State one thing TRANSLATE cannot do
       that REPLACE can.

  HINTS
    - app.Users.Email is NVARCHAR(256); app.Users.FullName is PERSISTED computed.
    - CHARINDEX returns 0 when the needle is absent — every email here has an '@',
      but note the risk.
    - UserId 19 (Sophie Wilson) has a NULL JobTitle. That is the divergence row.
    - TRANSLATE requires both character lists to be the same length.
=============================================================================*/

USE TaskFlowDb;
GO

-----------------------------------------------------------------------------
-- 1a. LEN vs DATALENGTH on app.Users.Email. What is the ratio, and why?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 1b. A literal with trailing spaces: LEN ignores them, DATALENGTH does not.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 2. LocalPart and Domain via LEFT / RIGHT / CHARINDEX
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 3. MaskedEmail via STUFF + REPLICATE  (ada.lovelace@... -> a*****e@...)
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 4. Initials from FirstName and LastName
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 5. Display string three ways: '+', CONCAT, CONCAT_WS.
--    Where do they differ, and why?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 6. TRANSLATE vs nested REPLACE on app.Tasks.MetadataJson.
--    What can REPLACE do that TRANSLATE cannot?
-----------------------------------------------------------------------------

-- TODO: your solution here
GO
