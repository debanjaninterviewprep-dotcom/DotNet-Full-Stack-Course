// P7 -- Design and Compare: Same Requirement, Three Layers  (Hard)
// See ../Practice-Problems.md for full requirements. Write-up: ./P7-comparison-table.md
//
// Requirement: given a ProjectId, return every open task's TaskId, Title, DueDate, and its
// primary assignee's FullName, ordered by DueDate ascending with NULLs last.
// Implement once each in raw ADO.NET, Dapper, and EF Core (LINQ, not raw SQL).
// All three must be correctly parameterised, async, and produce the same logical result.

using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace TaskFlow.Practice.Topic21;

public static class P7_ThreeLayersComparison
{
    // TODO: ADO.NET version

    // TODO: Dapper version

    // TODO: EF Core (LINQ) version
}
