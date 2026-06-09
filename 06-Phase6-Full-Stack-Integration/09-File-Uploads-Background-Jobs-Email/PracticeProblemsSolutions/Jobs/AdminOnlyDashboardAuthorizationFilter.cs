using Hangfire.Dashboard;

namespace TaskFlow.Topic09.Jobs;

// P3: lock /hangfire behind admin role. Replace IsAdmin check with your real auth.
public sealed class AdminOnlyDashboardAuthorizationFilter : IDashboardAuthorizationFilter
{
    public bool Authorize(DashboardContext context)
    {
        var http = context.GetHttpContext();
        // Dev fallback: allow on localhost only.
        if (http.Connection.RemoteIpAddress is null) return false;
        var isLocal = System.Net.IPAddress.IsLoopback(http.Connection.RemoteIpAddress);
        var isAdmin = http.User?.IsInRole("Admin") == true;
        return isAdmin || isLocal;
    }
}
