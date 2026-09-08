// P2 -- Connection Pooling Behavior  (Easy)
// See ../Practice-Problems.md for full requirements.
//
// 1. Open/dispose a SqlConnection in a tight loop (~50 iterations), one simple query each,
//    proper "await using" disposal each time.
// 2. Second, deliberately bad version: open 50 connections, hold them ALL open simultaneously
//    without disposing until the end (reason through the consequence if not practical to run).
// 3. Explain why version 1 reuses a small number of pooled physical connections while
//    version 2 risks pool exhaustion.
// 4. Name the exception type when the pool has no available connection and
//    Connection Timeout is exceeded.

using Microsoft.Data.SqlClient;

namespace TaskFlow.Practice.Topic21;

public static class P2_ConnectionPooling
{
    // TODO: your solution here
}
