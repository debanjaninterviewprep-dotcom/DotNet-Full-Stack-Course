# Solutions — M365 Copilot Integration

Put your work here following this structure:

```
PracticeProblemsSolutions/
├── README.md
├── P1-agent/
│   ├── appPackage/
│   │   ├── manifest.json
│   │   ├── declarativeAgent.json
│   │   ├── color.png
│   │   └── outline.png
│   └── screenshot.png
├── P2-plugin/
│   ├── taskflow-openapi.yaml
│   ├── taskflow-api-plugin.json
│   └── screenshot.png
├── P3-write-op/
│   ├── (updated yaml + plugin)
│   └── screenshot.png
├── P4-graph-connector/
│   ├── TaskFlow.Indexer/
│   │   ├── Program.cs
│   │   └── *.csproj
│   ├── screenshot-authorised.png
│   └── screenshot-unauthorised.png
├── P5-decomposition/
│   ├── plugin-read.json
│   ├── plugin-write.json
│   ├── plugin-admin.json
│   └── decomposition.md
├── P6-governance-checklist.md
└── P7-custom-engine-design.md
```

Tell me **"check"** when done.

---

## P1 Starter — `declarativeAgent.json`

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/copilot/declarative-agent/v1.2/schema.json",
  "version": "v1.2",
  "name": "TaskFlow Assistant",
  "description": "Helps the team explore TaskFlow projects, tasks, and SLA risk.",
  "instructions": "You are the TaskFlow Assistant. Always cite the source. If unsure, say so. Tone: concise, factual.",
  "conversation_starters": [
    { "title": "Project status", "text": "Summarise the status of project TF-2031" },
    { "title": "Overdue tasks",  "text": "Show my overdue tasks" },
    { "title": "Recent updates", "text": "What changed in TaskFlow this week?" },
    { "title": "SLA breaches",   "text": "Which projects breached SLA in the last 14 days?" },
    { "title": "Help",           "text": "What can you do?" }
  ],
  "capabilities": [
    {
      "name": "OneDriveAndSharePoint",
      "items_by_sharepoint_ids": []
    }
  ]
}
```

## P2 Starter — `taskflow-openapi.yaml`

```yaml
openapi: 3.0.3
info: { title: TaskFlow API, version: 1.0.0 }
servers: [{ url: https://api.taskflow.com }]
paths:
  /tasks/overdue:
    get:
      operationId: getOverdueTasks
      summary: Returns the current user's overdue tasks ordered by due date.
      security: [{ entraId: [TaskFlow.Read] }]
      responses:
        '200':
          description: List of overdue tasks
          content:
            application/json:
              schema: { $ref: '#/components/schemas/TaskList' }
  /projects/{projectId}:
    get:
      operationId: getProjectById
      summary: Returns a TaskFlow project by ID with summary and recent activity.
      parameters:
        - { name: projectId, in: path, required: true, schema: { type: string } }
      security: [{ entraId: [TaskFlow.Read] }]
      responses:
        '200':
          description: Project detail
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Project' }
  /projects:
    get:
      operationId: listProjects
      summary: Lists TaskFlow projects accessible to the current user.
      parameters:
        - { name: status, in: query, schema: { type: string, enum: [green, yellow, red] } }
        - { name: continuationToken, in: query, schema: { type: string } }
      security: [{ entraId: [TaskFlow.Read] }]
      responses:
        '200':
          description: Page of projects
          content:
            application/json:
              schema: { $ref: '#/components/schemas/ProjectPage' }
components:
  schemas:
    Task:
      type: object
      properties:
        id:    { type: string }
        title: { type: string }
        due:   { type: string, format: date-time }
        owner: { type: string }
    TaskList:
      type: object
      properties:
        value: { type: array, items: { $ref: '#/components/schemas/Task' } }
    Project:
      type: object
      properties:
        id:     { type: string }
        name:   { type: string }
        status: { type: string }
        owner:  { type: string }
    ProjectPage:
      type: object
      properties:
        value: { type: array, items: { $ref: '#/components/schemas/Project' } }
        continuationToken: { type: string }
  securitySchemes:
    entraId:
      type: oauth2
      flows:
        authorizationCode:
          authorizationUrl: https://login.microsoftonline.com/common/oauth2/v2.0/authorize
          tokenUrl: https://login.microsoftonline.com/common/oauth2/v2.0/token
          scopes:
            TaskFlow.Read: Read TaskFlow data
            TaskFlow.ReadWrite: Read and update TaskFlow data
```

## P4 Starter — Indexer skeleton (Program.cs)

```csharp
using Azure.Identity;
using Microsoft.Graph;
using Microsoft.Graph.Models.ExternalConnectors;

var credential = new DefaultAzureCredential();
var graph = new GraphServiceClient(credential, ["https://graph.microsoft.com/.default"]);

const string ConnectionId = "taskflow-projects";

// (1) Ensure connection exists (idempotent)
try
{
    await graph.External.Connections[ConnectionId].GetAsync();
}
catch
{
    await graph.External.Connections.PostAsync(new ExternalConnection
    {
        Id = ConnectionId,
        Name = "TaskFlow Projects",
        Description = "TaskFlow projects, indexed for Copilot grounding."
    });
}

// (2) Schema
await graph.External.Connections[ConnectionId].Schema.PatchAsync(new Schema
{
    BaseType = "microsoft.graph.externalItem",
    Properties =
    [
        new() { Name = "title",       Type = PropertyType.String,   IsSearchable = true, IsRetrievable = true },
        new() { Name = "status",      Type = PropertyType.String,   IsRefinable  = true, IsRetrievable = true },
        new() { Name = "owner",       Type = PropertyType.String,   IsRetrievable = true },
        new() { Name = "updatedDate", Type = PropertyType.DateTime, IsRefinable  = true }
    ]
});

// (3) Push items (sample)
foreach (var project in await LoadProjectsAsync())
{
    await graph.External.Connections[ConnectionId].Items[project.Id].PutAsync(new ExternalItem
    {
        Id = project.Id,
        Acl =
        [
            new Acl { Type = AclType.Group, Value = project.TeamEntraGroupId, AccessType = AccessType.Grant }
        ],
        Properties = new()
        {
            AdditionalData = new Dictionary<string, object>
            {
                ["title"]       = project.Name,
                ["status"]      = project.Status,
                ["owner"]       = project.Owner,
                ["updatedDate"] = project.UpdatedAt
            }
        },
        Content = new ExternalItemContent
        {
            Type = ExternalItemContentType.Text,
            Value = project.Description
        }
    });
}

static Task<List<ProjectDto>> LoadProjectsAsync() =>
    Task.FromResult(new List<ProjectDto>()); // replace with real loader

record ProjectDto(string Id, string Name, string Status, string Owner,
                  DateTime UpdatedAt, string TeamEntraGroupId, string Description);
```
