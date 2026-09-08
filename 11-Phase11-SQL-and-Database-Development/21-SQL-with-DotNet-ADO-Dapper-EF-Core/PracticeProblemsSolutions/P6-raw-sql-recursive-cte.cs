// P6 -- Safe Raw SQL in EF Core: FromSqlInterpolated for a Recursive CTE  (Hard)
// See ../Practice-Problems.md for full requirements.
//
// 1. FromSqlInterpolated running the Topic 07 org-chart recursive CTE against app.Users,
//    parameterising a starting @ManagerId value safely via string interpolation.
// 2. A DELIBERATELY VULNERABLE version using FromSqlRaw with manual string concatenation
//    of the same parameter -- explain how an attacker-controlled value could exploit it.
// 3. Explain why FromSqlInterpolated's $"..." syntax is safe despite looking identical
//    to ordinary (unsafe) C# string interpolation.
// 4. State one limitation of FromSqlInterpolated/FromSqlRaw results vs a normal
//    LINQ-composed query.

using Microsoft.EntityFrameworkCore;

namespace TaskFlow.Practice.Topic21;

public static class P6_RawSqlRecursiveCte
{
    // TODO: your solution here
}
