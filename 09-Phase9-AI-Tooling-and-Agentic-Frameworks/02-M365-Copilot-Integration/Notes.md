# Topic 2: Microsoft 365 Copilot Integration

## What You'll Learn

How **Microsoft 365 Copilot** works under the hood, and how a developer **extends** it — declarative agents, custom plugins, connectors, and the Teams Toolkit workflow. By the end you can ship an agent that searches TaskFlow data from inside Teams or Word.

> **GitHub Copilot ≠ Microsoft 365 Copilot.** They share a brand and a model family, nothing else. Different licence, different surface, different extensibility model.

---

## 1. What M365 Copilot Actually Is

M365 Copilot is an **assistant layered on the Microsoft Graph** and the M365 client surfaces (Word, Excel, Outlook, Teams, PowerPoint, Loop, OneNote, Stream, and the standalone Copilot Chat app).

```
            ┌────────────────────────────────┐
            │  Foundation models             │  GPT / o-series via Azure
            └──────────────┬─────────────────┘
                           ▼
            ┌────────────────────────────────┐
            │  M365 Copilot orchestrator     │  prompt orchestration, grounding,
            │  + Semantic Index over Graph   │  responsible AI filter
            └────────┬──────────────┬────────┘
                     ▼              ▼
        ┌──────────────────┐  ┌─────────────────────┐
        │ Microsoft Graph  │  │ Extensibility:      │
        │ (your tenant)    │  │  declarative agents │
        │  - email         │  │  custom engine      │
        │  - files         │  │  connectors         │
        │  - chats         │  │  plugins / actions  │
        │  - calendar      │  │  Graph connectors   │
        └──────────────────┘  └─────────────────────┘
```

Key properties:
- **Tenant-isolated.** Prompts and grounded content stay inside your Microsoft 365 commercial cloud boundary. Your data is **not** used to train foundation models.
- **Grounded by default.** Every answer can cite Graph items (a file, an email, a chat).
- **Permission-trimmed.** Copilot only surfaces content the asking user can already see.
- **Responsible AI.** Outputs are filtered for harm, IP, and prompt injection.

### Licensing & Prereqs (mid-2026)

- **Microsoft 365 Copilot** licence per user (annual commitment).
- Underlying M365 plan (E3/E5, Business Standard/Premium).
- Entra ID identities; mailbox in Exchange Online; files in OneDrive/SharePoint Online for grounding.

### Where it shows up
- **Copilot Chat** (formerly BizChat) — standalone web/Teams app, Graph-grounded.
- **Copilot in apps** — Word "draft with Copilot", Excel formula generation, Outlook reply suggestions, PowerPoint "create from prompt", Teams meeting recap.
- **Copilot Pages** — collaborative AI-drafted artifacts.
- **Copilot Studio** — low-code agent authoring.

---

## 2. Extensibility: The Four Patterns

When you want Copilot to **know about** or **act on** your system (TaskFlow), there are four extension models. Pick by use case.

| Pattern | Best for | Effort | Surface |
|---|---|---|---|
| **Graph connector** | "Make my external data searchable & cite-able" | Low | All M365 Copilot surfaces, Search |
| **Declarative agent** | "A custom Copilot scoped to a topic with curated knowledge & instructions" | Low | Copilot Chat, Teams |
| **API plugin (action)** | "Let Copilot call my API to read/write data" | Medium | Declarative or custom-engine agent |
| **Custom engine agent** | "I want full control of orchestration and the model" | High | Teams, embedded apps |

Mental model: **Connector = passive data; Agent = active persona; Plugin = capability the agent calls; Custom engine = your own brain.**

---

## 3. Declarative Agents — The Starting Point

A **declarative agent** = `manifest.json` (instructions, conversation starters, knowledge sources, plugins). No code in the simple case.

Minimal example (`declarativeAgent.json`):

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/copilot/declarative-agent/v1.2/schema.json",
  "version": "v1.2",
  "name": "TaskFlow Assistant",
  "description": "Helps the team query projects, tasks, and SLA status in TaskFlow.",
  "instructions": "You are the TaskFlow Assistant. Always cite the project ID in responses. If a question concerns billing, refer the user to the Finance channel.",
  "conversation_starters": [
    { "title": "Show overdue tasks", "text": "Which of my tasks are overdue?" },
    { "title": "Project health",     "text": "Summarise the status of project TF-2031." },
    { "title": "SLA breaches",       "text": "List SLA breaches in the last 7 days." }
  ],
  "capabilities": [
    { "name": "WebSearch" },
    {
      "name": "OneDriveAndSharePoint",
      "items_by_sharepoint_ids": [
        { "site_id": "...", "web_id": "...", "list_id": "...", "unique_id": "..." }
      ]
    }
  ],
  "actions": [
    { "id": "taskflow-api", "file": "taskflow-api-plugin.json" }
  ]
}
```

The manifest is packaged with a `manifest.json` (Teams app manifest) + icons into a zip, then sideloaded or published to the org/M365 admin centre.

**Capabilities** include WebSearch, GraphConnectors, OneDriveAndSharePoint, PeopleSearch, EmailMessages, Calendar, TeamsMessages — these let the agent ground answers in those sources without you writing any code.

**Actions** point at API plugin files (next section).

---

## 4. API Plugins (Actions) — Letting Copilot Call Your API

An API plugin is a **manifest** (`taskflow-api-plugin.json`) that points at an **OpenAPI 3.x document** describing your API. Copilot reads the OpenAPI spec to know which operations exist, what parameters they need, and how to call them.

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/copilot/plugin/v2.2/schema.json",
  "schema_version": "v2.2",
  "name_for_human": "TaskFlow API",
  "namespace": "taskflow",
  "description_for_human": "Read and update TaskFlow projects, tasks, and SLAs.",
  "description_for_model": "Use this plugin to read projects/tasks and update task status. Confirm with the user before any write.",
  "functions": [
    {
      "name": "getOverdueTasks",
      "description": "Returns tasks past their due date for the current user.",
      "capabilities": { "response_semantics": { "data_path": "$.value" } }
    },
    {
      "name": "updateTaskStatus",
      "description": "Updates a task status. Requires explicit user confirmation.",
      "capabilities": { "confirmation": { "type": "AdaptiveCard", "title": "Confirm status update" } }
    }
  ],
  "runtimes": [
    {
      "type": "OpenApi",
      "auth": { "type": "OAuthPluginVault", "reference_id": "auth_provider_id" },
      "spec": { "url": "taskflow-openapi.yaml" },
      "run_for_functions": ["getOverdueTasks", "updateTaskStatus"]
    }
  ]
}
```

### What makes a plugin good (vs broken)

1. **OpenAPI fidelity.** Every operation has a clear `summary`, `description`, parameter `description`, and tight response schema. Copilot picks the right operation purely from these strings.
2. **Operation count.** Aim for 5–15 operations per plugin. Bigger plugins confuse the orchestrator and miss-route calls.
3. **Idempotency for writes.** Plus user-confirmation cards on destructive operations.
4. **Auth.** OAuth 2.0 via Entra ID is the only realistic option for tenant data. Anonymous APIs are dev-toy only.
5. **Naming.** Operation `operationId`s should read like sentences: `getOverdueTasks`, `assignTaskToUser`, not `getApiV1TasksOverdueGet`.

### OpenAPI sample slice

```yaml
openapi: 3.0.3
info: { title: TaskFlow, version: 1.0.0 }
servers: [{ url: https://api.taskflow.com }]
paths:
  /tasks/overdue:
    get:
      operationId: getOverdueTasks
      summary: Returns the current user's overdue tasks.
      responses:
        '200':
          description: List of overdue tasks
          content:
            application/json:
              schema: { $ref: '#/components/schemas/TaskList' }
      security: [{ entraId: [TaskFlow.Read] }]
  /tasks/{taskId}/status:
    patch:
      operationId: updateTaskStatus
      summary: Update a task's status. Confirm with user before calling.
      parameters:
        - { name: taskId, in: path, required: true, schema: { type: string } }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/StatusUpdate' }
      responses:
        '200': { description: Updated }
      security: [{ entraId: [TaskFlow.ReadWrite] }]
components:
  securitySchemes:
    entraId:
      type: oauth2
      flows:
        authorizationCode:
          authorizationUrl: https://login.microsoftonline.com/common/oauth2/v2.0/authorize
          tokenUrl: https://login.microsoftonline.com/common/oauth2/v2.0/token
          scopes:
            TaskFlow.Read: Read tasks
            TaskFlow.ReadWrite: Update tasks
```

---

## 5. Microsoft Graph Connectors — Making External Data Discoverable

If TaskFlow data lives outside SharePoint/OneDrive and you want it to **show up in Copilot answers as citations**, you build a Graph connector.

Two flavours:
- **Built-in connectors** (ServiceNow, Salesforce, Jira, etc.) — admin configures, no code.
- **Custom connector** — write a Microsoft Graph connector using the Graph API; you push items + ACLs into the tenant's semantic index.

Skeleton (C# using `Microsoft.Graph`):

```csharp
// 1. Register connection (one-time)
var connection = new ExternalConnection
{
    Id = "taskflow-projects",
    Name = "TaskFlow Projects",
    Description = "All TaskFlow projects, indexed for Copilot grounding."
};
await graph.External.Connections.PostAsync(connection);

// 2. Define schema
var schema = new Schema
{
    BaseType = "microsoft.graph.externalItem",
    Properties = new()
    {
        new() { Name = "title",       Type = PropertyType.String,  IsSearchable = true, IsRetrievable = true },
        new() { Name = "status",      Type = PropertyType.String,  IsRefinable  = true, IsRetrievable = true },
        new() { Name = "owner",       Type = PropertyType.String,  IsRetrievable = true },
        new() { Name = "updatedDate", Type = PropertyType.DateTime, IsRefinable = true }
    }
};
await graph.External.Connections["taskflow-projects"].Schema.PatchAsync(schema);

// 3. Push items (incremental, with ACLs)
var item = new ExternalItem
{
    Id = project.Id.ToString(),
    Acl = new() {
        new Acl { Type = AclType.Group, Value = project.TeamGroupId, AccessType = AccessType.Grant }
    },
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
};
await graph.External.Connections["taskflow-projects"]
    .Items[project.Id.ToString()].PutAsync(item);
```

Once items are indexed, M365 Copilot can cite them in answers ("From TaskFlow project TF-2031, owned by Maya, status Yellow...").

ACL caveats:
- ACLs are evaluated **per query** — only items the user can read appear in their results.
- Group ACLs use Entra group IDs.
- Keep ACLs **fresh** — drift causes either over-sharing or under-sharing.

---

## 6. Tooling: Teams Toolkit / Microsoft 365 Agents Toolkit

The official scaffolding tool is the **Microsoft 365 Agents Toolkit** (formerly Teams Toolkit). It exists for VS Code and CLI (`atk`).

Lifecycle:

```
   atk new ──▶ scaffold ──▶ atk provision ──▶ atk deploy ──▶ atk preview
                              (Entra app +     (app pkg)      (sideload + open
                               app reg)                        Copilot Chat)
```

A scaffolded declarative agent project structure:

```
my-agent/
├── appPackage/
│   ├── manifest.json                 (Teams app manifest)
│   ├── declarativeAgent.json
│   ├── plugin/
│   │   ├── ai-plugin.json
│   │   └── openapi.yaml
│   ├── color.png
│   └── outline.png
├── env/
│   ├── .env.dev
│   └── .env.local
└── m365agents.yml                    (pipeline definition)
```

`m365agents.yml` describes the deploy stages: create Entra registration, upload manifest to Teams Developer Portal, register API connection in Copilot, etc. The toolkit handles them; you don't hand-craft Entra apps.

For local debugging the toolkit spins up an API tunnel (devtunnels) so the cloud-hosted Copilot can reach `localhost`.

---

## 7. Custom Engine Agents (Brief)

When declarative + plugins aren't enough — for example, you want **your own orchestration** (multi-step planning, custom tools, non-OpenAPI services) — build a **custom engine agent**.

Stack:
- Bot Framework SDK (C# or TypeScript) hosted on Azure Bot Service.
- Calls Azure OpenAI or any other model.
- Implements the orchestration logic yourself (often with Semantic Kernel — see Topic 3).
- Surfaces through Teams or as a Copilot agent.

Trade-off: maximum control, maximum cost (devops, governance, hosting). 90% of integrations are better served by declarative agents with plugins.

---

## 8. Security & Governance

### Identity & permission
- Entra ID is the only identity provider. Every API call from a plugin uses delegated user permissions — never app-only for user-facing data.
- Define scopes (e.g., `TaskFlow.Read`, `TaskFlow.ReadWrite.Self`) and apply them via OAuth `security` in OpenAPI.
- Admin consent for tenant-wide use; user consent for personal scopes.

### Tenant boundary
- Copilot processing for grounding stays in the tenant's M365 commercial geography.
- Foundation model inference may use Azure OpenAI capacity in-region; check tenant settings for EU Data Boundary / sovereign clouds.

### Data residency / DLP
- Sensitivity labels (MIP) propagate. If a file is labelled **Confidential**, Copilot honours its policy (e.g., can't paste content into a chat that violates label rules).
- DLP policies apply to Copilot Chat as a workload.
- Customer Lockbox supported.

### Auditing
- Every Copilot interaction logged to **Microsoft Purview / unified audit log**.
- Use Purview Data Lifecycle Management for retention.
- Use Adoption Score / Copilot Dashboard for usage and "responsible use" trends.

### Responsible AI
- Prompt-injection mitigations applied in the orchestrator. Untrusted text from emails/files is treated as data, not instruction.
- Citations required for grounded answers; output filtered for harm.

### Plugin governance
- Admin can allow/block specific plugins per tenant.
- Pilot in a small group → rollout with adoption metrics.

---

## 9. Anti-Patterns

| Anti-pattern | Why it's bad | Better |
|---|---|---|
| Building a custom engine agent for everything | Cost + governance overhead | Start declarative; only escalate when you hit a wall |
| Anonymous APIs in plugins | Data leak; not deployable to enterprise tenants | Entra OAuth with scopes |
| 80-operation plugins | Orchestrator picks wrong tool | Split into focused plugins |
| Plain-text grounding URLs in instructions | No ACL trimming | Use Graph connectors with proper ACLs |
| Confidential corpus pushed via connector with `everyone` ACL | Tenant-wide leak | ACL per group |
| OpenAPI operations with one-word descriptions | Copilot can't pick the right one | Sentence-length, intent-rich descriptions |
| No telemetry from your plugin API | Can't debug bad routing | Log every Copilot-triggered call with correlation ID |
| Skipping pilot phase | Adoption tanks; trust burned | 2–4 week pilot before tenant rollout |

---

## 10. Decision Flow: Which Pattern Do I Use?

```
Q: Do you just want your data to show up in Copilot answers (read-only)?
   → Graph connector.

Q: Do you want a topical "Copilot persona" that knows about a domain + cites curated docs?
   → Declarative agent with knowledge capabilities (SharePoint/OneDrive/Web).

Q: Does the agent need to read or write back into your system?
   → Declarative agent + API plugin (with OpenAPI).

Q: Do you need multi-step planning, custom orchestration, non-OpenAPI tools,
   or to host the agent outside M365?
   → Custom engine agent (Bot Framework + Semantic Kernel / Agent Framework).
```

---

## 11. Mental Model

> M365 Copilot is a frontend over your tenant's data. Declarative agents give it a persona; plugins give it capabilities; connectors give it knowledge. Build in that order; escalate to custom engine only when the declarative path is exhausted.

Move to [Practice Problems](./Practice-Problems.md).
