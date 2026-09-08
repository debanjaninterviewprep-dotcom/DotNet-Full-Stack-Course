// P1 -- Raw ADO.NET: Parameters Done Right and Wrong  (Easy)
// See ../Practice-Problems.md for full requirements.
//
// 1. Fetch tasks for a ProjectId using an explicitly-typed SqlParameter (SqlDbType.Int).
// 2. Second version: Parameters.AddWithValue for a Title search filter (NVARCHAR(200) column) --
//    explain the specific type-inference risk this introduces.
// 3. Capture whether the AddWithValue version's parameter type matches the column's declared
//    type exactly -- state the consequence if it doesn't.
// 4. Rewrite using an explicitly-sized SqlDbType.NVarChar, 200 parameter instead -- confirm match.

using Microsoft.Data.SqlClient;

namespace TaskFlow.Practice.Topic21;

public static class P1_AdoNetParameters
{
    // TODO: your solution here
}
