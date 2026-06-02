using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Testcontainers.MsSql;
using Xunit;

namespace TaskFlow.Topic10.Integration;

// P2: WebApplicationFactory bound to a Testcontainers SQL Server.
//
// Replace `Program` with your real API entry-point class (must be `partial`).
// e.g. using TaskFlow.Api;  -> WebApplicationFactory<TaskFlow.Api.Program>
public sealed class TaskFlowApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly MsSqlContainer _sql = new MsSqlBuilder()
        .WithPassword("Y0urStrong!Passw0rd")
        .Build();

    public string ConnectionString => _sql.GetConnectionString();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        // TODO P2: ConfigureTestServices(s => { s.RemoveAll<DbContextOptions<TaskFlowDbContext>>();
        //                                     s.AddDbContext<TaskFlowDbContext>(o => o.UseSqlServer(ConnectionString)); });
    }

    public async Task InitializeAsync()
    {
        await _sql.StartAsync();
        // TODO P2: using var scope = Services.CreateScope();
        //          var db = scope.ServiceProvider.GetRequiredService<TaskFlowDbContext>();
        //          await db.Database.MigrateAsync();
    }

    public new async Task DisposeAsync()
    {
        await _sql.DisposeAsync();
        await base.DisposeAsync();
    }
}

[CollectionDefinition("Api")]
public sealed class ApiCollection : ICollectionFixture<TaskFlowApiFactory> { }

// Stand-in: every API in Phase 6 ends Program.cs with `public partial class Program { }`.
public partial class Program { }
