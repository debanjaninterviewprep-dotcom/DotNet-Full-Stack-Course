/*
    P6 -- Reproducing and Handling a Deadlock  (Hard -- requires TWO sessions)
    See ../Practice-Problems.md for full requirements.
    Precise interleaving is required to reliably reproduce the deadlock -- follow the
    numbered steps across the two windows exactly in order.

    1. Reverse-order deadlock: SESSION A updates a Tasks row then attempts a Projects row;
       SESSION B updates the SAME Projects row then attempts the SAME Tasks row, interleaved
       so each blocks on the other.
    2. Confirm SQL Server picks a deadlock victim with error 1205; the other session completes.
    3. Rewrite BOTH sessions to access Tasks before Projects in EVERY case (consistent
       ordering) -- confirm no deadlock under the same interleaving.
    4. Wrap the ORIGINAL (reverse-order) scenario in the retry pattern (TRY/CATCH checking
       ERROR_NUMBER() = 1205) -- demonstrate it completes successfully after a retry.
    5. Reset all data changes.
*/
USE TaskFlowDb;
GO

-- ============================================================
-- SESSION A
-- ============================================================
-- TODO: your solution here

-- ============================================================
-- SESSION B
-- ============================================================
-- TODO: your solution here
