// P3 -- Dapper: Query, Multi-Mapping, and Stored Procedure Calls  (Medium)
// See ../Practice-Problems.md for full requirements.
//
// 1. QueryAsync<TaskDto> fetching open tasks for a project, anonymous object parameter.
// 2. Multi-mapping query joining app.Tasks to app.Projects, populating TaskDto.Project,
//    with the correct splitOn parameter.
// 3. Call app.usp_CreateTask (Topic 15) via Dapper with an output parameter, using
//    DynamicParameters -- retrieve the output value afterward.
// 4. Explain why Dapper's `new { ProjectId = projectId }` pattern is injection-safe by
//    default (Topic 19).

using Dapper;
using Microsoft.Data.SqlClient;

namespace TaskFlow.Practice.Topic21;

public static class P3_DapperPatterns
{
    // TODO: your solution here
}
