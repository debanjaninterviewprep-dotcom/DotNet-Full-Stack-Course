// P4 -- Reproducing and Fixing N+1 in EF Core  (Medium)
// See ../Practice-Problems.md for full requirements.
//
// 1. Load all projects, then (inside a loop) access each project's Tasks.Count via a
//    lazy-loaded navigation property -- the N+1 bug.
// 2. Capture (via .LogTo(...) or reasoned through) the actual SQL statement count for
//    8 projects (expect 1 + 8 = 9).
// 3. Fix two ways: .Include(p => p.Tasks) (eager loading), then a direct .Select()
//    projection computing the count in SQL. Capture the statement count for both.
// 4. Explain which fix is preferable for "just show me a count" and why.

using Microsoft.EntityFrameworkCore;

namespace TaskFlow.Practice.Topic21;

public static class P4_NPlusOne
{
    // TODO: your solution here
}
