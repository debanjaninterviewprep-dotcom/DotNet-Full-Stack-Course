// P5 -- AsNoTracking() and Its Effect  (Medium)
// See ../Practice-Problems.md for full requirements.
//
// 1. Query fetching tasks for a project WITHOUT AsNoTracking() -- explain exactly what
//    the change tracker does with each returned entity.
// 2. Rewrite WITH .AsNoTracking() -- explain what's skipped.
// 3. Describe the scenario where tracking is genuinely needed vs pure overhead.
// 4. Identify one place in a typical TaskFlow API controller where AsNoTracking()
//    should almost always be used.

using Microsoft.EntityFrameworkCore;

namespace TaskFlow.Practice.Topic21;

public static class P5_AsNoTracking
{
    // TODO: your solution here
}
