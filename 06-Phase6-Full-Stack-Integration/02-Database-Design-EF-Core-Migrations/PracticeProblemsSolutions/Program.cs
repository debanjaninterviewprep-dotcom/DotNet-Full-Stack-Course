using Microsoft.EntityFrameworkCore;

namespace TaskFlow.Topic02;

internal class Program
{
    static async Task Main(string[] args)
    {
        // ===============================
        // Problem 1: TaskFlow ERD
        // ===============================
        // Design-only deliverable. Place your mermaid erDiagram in Solutions/P1-erd.md.

        Console.WriteLine("Problem 1 — see Solutions/P1-erd.md");

        // ===============================
        // Problem 2: User & RefreshToken Entities + DbContext
        // ===============================
        // Implement User, RefreshToken, configurations, and TaskFlowDbContext.
        // Use SQLite for a quick local run: "Data Source=taskflow.db".

        // TODO: Write your solution here


        // ===============================
        // Problem 3: Project ↔ User Many-to-Many with ProjectMember
        // ===============================
        // Add Project, ProjectMember (composite key, Role, JoinedAt). Demonstrate
        // adding members, role change, and listing a user's projects.

        // TODO: Write your solution here


        // ===============================
        // Problem 4: Audit Interceptor + Soft-Delete Filter
        // ===============================
        // Implement IAuditable / ISoftDelete, AuditInterceptor : SaveChangesInterceptor,
        // and HasQueryFilter on all soft-deletable entities. Prove behavior.

        // TODO: Write your solution here


        // ===============================
        // Problem 5: Migrations — Initial + Rename via Expand/Contract
        // ===============================
        // 1. dotnet ef migrations add InitialCreate
        // 2. dotnet ef migrations script -i -o ./Solutions/initial.sql
        // 3. Add Summary (nullable) + copy data + drop Description across two migrations.
        // Document the deploy plan in Solutions/P5-deploy-plan.md.

        // TODO: Write your solution here


        // ===============================
        // Problem 6: N+1-Free Project Listing + Indexing Plan
        // ===============================
        // Implement ListProjectsAsync(...) returning ProjectListItemDto rows in a single
        // SQL query, with keyset pagination by (LastActivityAt DESC, Id DESC).
        // Document indexes in Solutions/P6-indexes.md.

        // TODO: Write your solution here

        await Task.CompletedTask;
    }
}
