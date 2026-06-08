# Topic 3: Microsoft Agentic Frameworks Overview

## What You'll Learn

The landscape, architecture, and mental model for building **AI agents** in the Microsoft ecosystem — Semantic Kernel, Microsoft Agent Framework, AutoGen, Copilot Studio — when each fits, and the building blocks they share (models, tools, memory, planning, multi-agent orchestration). By the end you can pick the right framework for a use case and stand up a working agent in .NET.

---

## 1. What "Agentic" Actually Means

A useful working definition:

> An **AI agent** is a software component that, given a goal, can autonomously decide which **tools** to call, in what order, using a **foundation model** for reasoning — and produce a result without step-by-step human direction.

Three things distinguish an "agent" from "an LLM behind an API":

1. **Tools / function calling** — the model can invoke real code (your APIs, databases, search).
2. **Planning / loop** — the model decides the next step based on prior step results; the runtime executes it.
3. **State / memory** — the agent carries context across turns (conversation, working notes, long-term store).

```
                ┌───────────────────────────────┐
                │       Foundation Model        │
                │  (decides next action / msg)  │
                └─────────────┬─────────────────┘
                              │ "call tool X with args Y"
                              ▼
                ┌───────────────────────────────┐
                │       Orchestrator            │  the framework's job
                │  - tool catalog               │
                │  - executes tool calls        │
                │  - feeds results back         │
                │  - manages history / memory   │
                └───────────────────────────────┘
                              │
              ┌───────────────┼──────────────────┐
              ▼               ▼                  ▼
     ┌────────────┐   ┌──────────────┐   ┌──────────────┐
     │ HTTP / API │   │  DB / Vector │   │ Other agents │
     │   tools    │   │  store       │   │ (multi-agent)│
     └────────────┘   └──────────────┘   └──────────────┘
```

The model is the **brain**; the framework is the **body and reflexes**.

---

## 2. The Microsoft Agentic Stack — Who Does What

There are several Microsoft frameworks. They sound similar; they are **not interchangeable**.

| Framework | Audience | Position | Maturity (mid-2026) |
|---|---|---|---|
| **Semantic Kernel (SK)** | .NET / Python developers building agents in code | Production-grade kernel, plugins, planners, vector connectors | GA, widely used |
| **Microsoft Agent Framework (MAF)** | .NET / Python developers building multi-agent workflows | Newer unifying framework merging SK + AutoGen patterns | GA (Microsoft.Agents.AI) |
| **AutoGen** | Researchers / advanced multi-agent experimentation | Open-source, conversation-driven multi-agent patterns | Active; many ideas absorbed into MAF |
| **Copilot Studio** | Low-code / fusion teams | Visual agent builder over M365 + Power Platform | GA |
| **Azure AI Foundry Agent Service** | Cloud-managed agents with built-in tools, threads, files | Hosted runtime + SDKs | GA |
| **Bot Framework SDK** | Conversational bots needing rich channel surface | Channel adapters + dialogs; pre-agent era | GA / mature |
| **M365 declarative agents** | M365 surface agents (Topic 2) | Manifest-driven; no orchestration code | GA |

### Quick selection guide

```
Q: Low-code? Citizen developer?                     → Copilot Studio
Q: Just M365 surface, low orchestration?            → Declarative agent (Topic 2)
Q: .NET code, single-agent with tools + memory?     → Semantic Kernel
Q: .NET code, multi-agent orchestration?            → Microsoft Agent Framework
Q: Want managed hosting + built-in tools + threads? → Azure AI Foundry Agent Service
Q: Conversational bot needing many channels?        → Bot Framework SDK + SK plugins
Q: Research / novel multi-agent patterns?           → AutoGen
```

---

## 3. Semantic Kernel — The Workhorse

SK is the most-deployed Microsoft agent framework today and remains the foundation many higher-level frameworks (including MAF) build on.

### Core concepts

- **Kernel** — central object holding configuration, services (chat model, embeddings), plugins.
- **Plugins / Functions** — units of capability (native C# functions, prompt templates, OpenAPI imports).
- **Chat completion service** — model adapter (Azure OpenAI, OpenAI, Hugging Face, local).
- **Function calling** — automatic tool invocation through OpenAI-style function specs.
- **Vector connectors** — Azure AI Search, Qdrant, Redis, Cosmos DB, etc.
- **Filters** — interceptors around model and function calls (logging, redaction, policy).
- **Agents (Agents API)** — `ChatCompletionAgent`, `AzureAIAgent`, `OpenAIAssistantAgent`, etc.
- **Process / Workflow** — newer feature for graph-based step orchestration.

### Minimal example — a TaskFlow agent (.NET 8)

```csharp
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Agents;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;

var builder = Kernel.CreateBuilder();

builder.AddAzureOpenAIChatCompletion(
    deploymentName: "gpt-4o",
    endpoint: cfg["AzureOpenAI:Endpoint"]!,
    apiKey:   cfg["AzureOpenAI:ApiKey"]!);

builder.Plugins.AddFromType<TaskFlowPlugin>();

var kernel = builder.Build();

var agent = new ChatCompletionAgent
{
    Name         = "TaskFlowAgent",
    Instructions = """
        You help the user inspect and update TaskFlow projects and tasks.
        Always ask for confirmation before any write operation.
        Be concise.
        """,
    Kernel       = kernel,
    Arguments    = new(new OpenAIPromptExecutionSettings
    {
        ToolCallBehavior = ToolCallBehavior.AutoInvokeKernelFunctions
    })
};

var chat = new ChatHistory();
chat.AddUserMessage("What are my overdue tasks for project TF-2031?");

await foreach (var msg in agent.InvokeAsync(chat))
    Console.WriteLine($"{msg.Role}: {msg.Content}");
```

The plugin is plain C#:

```csharp
public sealed class TaskFlowPlugin(ITaskFlowApi api)
{
    [KernelFunction, Description("Return tasks past their due date for a project.")]
    public async Task<IReadOnlyList<TaskDto>> GetOverdueTasksAsync(
        [Description("Project ID like TF-2031")] string projectId,
        CancellationToken ct = default)
        => await api.GetOverdueAsync(projectId, ct);

    [KernelFunction, Description("Update the status of a TaskFlow task.")]
    public Task UpdateStatusAsync(
        [Description("Task ID")] string taskId,
        [Description("New status: todo|in_progress|done|blocked")] string status,
        CancellationToken ct = default)
        => api.UpdateStatusAsync(taskId, status, ct);
}
```

That's a working agent. `ToolCallBehavior.AutoInvokeKernelFunctions` is the loop: model proposes calls, runtime executes, feeds results back, repeats until the model returns a final user-facing message.

### Memory in SK

- **Short-term:** `ChatHistory`. You decide retention policy (window, summarisation, full).
- **Long-term:** Vector store (e.g., Azure AI Search). Add `Microsoft.Extensions.VectorData` connectors. Use embeddings (`AddAzureOpenAITextEmbeddingGeneration`). Wrap as a plugin so the model can search it.

### Filters / governance

```csharp
kernel.FunctionInvocationFilters.Add(new AuditFilter(_logger));
kernel.PromptRenderFilters.Add(new RedactPiiFilter());
```

Filters are how you bolt on logging, redaction, retry policies, and policy enforcement without changing plugin code.

---

## 4. Microsoft Agent Framework (MAF) — The Unifier

MAF is Microsoft's next-generation agent SDK that **merges Semantic Kernel + AutoGen patterns** into a unified API for both single-agent and multi-agent scenarios. Package: `Microsoft.Agents.AI` (.NET) and `agent-framework` (Python).

Conceptual additions on top of SK:

| Concept | Purpose |
|---|---|
| `AIAgent` | First-class agent abstraction — wraps model, instructions, tools |
| `AgentThread` | Long-lived conversation/state container, agnostic of provider |
| `Workflow` | Typed, graph-based orchestration of agents and steps |
| Multi-agent patterns | Sequential, concurrent, handoff, group-chat |
| Observability built-in | OpenTelemetry traces for every model + tool call |
| Human-in-the-loop checkpoints | Pause workflow for approval |

### Minimal example — single agent with MAF (.NET)

```csharp
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;
using Azure.AI.OpenAI;
using Azure.Identity;

var chatClient = new AzureOpenAIClient(
        new Uri(cfg["AzureOpenAI:Endpoint"]!),
        new DefaultAzureCredential())
    .GetChatClient("gpt-4o")
    .AsIChatClient();

AIAgent agent = chatClient.CreateAIAgent(
    name: "TaskFlowAgent",
    instructions: "You help users explore TaskFlow data. Be concise.",
    tools:
    [
        AIFunctionFactory.Create(GetOverdueTasksAsync),
        AIFunctionFactory.Create(UpdateStatusAsync)
    ]);

var thread = agent.GetNewThread();
var response = await agent.RunAsync("What are my overdue tasks?", thread);
Console.WriteLine(response.Text);
```

Tool callbacks are plain async methods with `[Description]` attributes.

### Multi-agent workflow (sketch)

```csharp
var planner = chatClient.CreateAIAgent(name: "Planner",  instructions: "Decompose the goal into steps.");
var coder   = chatClient.CreateAIAgent(name: "Coder",    instructions: "Write code for each step.");
var critic  = chatClient.CreateAIAgent(name: "Critic",   instructions: "Review code for bugs and security.");

var workflow = AgentWorkflowBuilder
    .CreateGroupChatBuilderWith(participants => new RoundRobinGroupChatManager
    {
        MaximumIterationCount = 6
    })
    .AddParticipants(planner, coder, critic)
    .Build();

await using var run = await InProcessExecution.RunAsync(workflow, "Build a CSV importer for TaskFlow.");
await foreach (var ev in run.WatchStreamAsync())
    Console.WriteLine(ev);
```

Patterns supported:
- **Sequential** — A → B → C.
- **Concurrent** — A and B in parallel, results merged.
- **Hand-off** — agents decide who's next.
- **Group chat** — agents speak in a managed conversation until a manager declares done.

### When to choose MAF over SK
- You need multi-agent orchestration with first-class workflow support.
- You want richer telemetry and HITL out of the box.
- You're starting greenfield in 2026+.

When to stay with SK:
- Existing SK codebase that works.
- You only need single-agent + plugins; MAF adds concepts you won't use.

---

## 5. AutoGen — Multi-Agent Conversation Patterns

AutoGen (Microsoft Research origin, now part of the agentic family) pioneered patterns like:

- **Two-agent chat** (assistant + user-proxy).
- **Group chat** with a manager agent picking who speaks next.
- **Code-executor agent** that actually runs generated Python/Bash in a sandbox.
- **Selector / round-robin / hand-off** speaker policies.

Many of these patterns were absorbed into MAF. AutoGen remains the **research toolkit** for exploring novel multi-agent designs; production deployments typically settle on SK or MAF.

Use AutoGen when:
- You're prototyping a novel multi-agent design that doesn't fit standard patterns.
- You're in Python and want the largest ecosystem of multi-agent examples.

Avoid AutoGen when:
- You need long-term .NET support with Microsoft's standard governance/observability story.

---

## 6. Copilot Studio — The Low-Code Path

Copilot Studio (formerly Power Virtual Agents) is the low-code visual agent builder. Topics, generative answers, knowledge sources, actions (via Power Platform connectors). Behind the scenes it uses similar primitives, but you author visually.

Use when:
- Business team owns the bot.
- Integrations are mostly Power Platform / M365 / standard SaaS.
- Code-grade extensibility is not required.

Don't use when:
- You need custom orchestration, complex state, or testing rigour at the level of a normal .NET project.

It is **not** competing with SK / MAF — it's a different audience.

---

## 7. Azure AI Foundry Agent Service

A hosted runtime for agents with batteries-included tools (file search, code interpreter, function tools, OpenAPI tools, browsing) and a managed **thread** primitive for persistent state. Provider-agnostic from your perspective: build with SK or MAF and target the Agent Service, or use its SDK directly.

Why hosted matters:
- Threads, tool registry, evaluations, traces are all managed.
- You stop carrying conversation state in your DB.
- Native integration with Azure AI Search, Bing Grounding, Azure Functions tools.

Trade-off:
- You commit to the Azure-managed runtime; some control surfaces are abstracted away.

---

## 8. The Building Blocks (Universal Across Frameworks)

These exist in every framework — the names change.

### 8.1 Models
- Azure OpenAI (GPT-4o, GPT-4.1, o-series, etc.).
- OpenAI direct (where allowed by data policy).
- Phi-3 / Phi-4 (small local models).
- Hugging Face / OSS through `ONNX Runtime GenAI` or `Microsoft.Extensions.AI` providers.
- Multimodal models for image/audio input.

### 8.2 Tools / Functions
- Native code functions (most common).
- OpenAPI imports (one big plugin per spec).
- MCP (Model Context Protocol) servers — Topic 5 covers this in more depth.
- Vector search "as a tool".

### 8.3 Memory
- Short-term: chat history (windowed, summarised, or persisted thread).
- Working memory: scratchpad / per-step notes.
- Long-term: vector DB (semantic search) + relational DB (structured facts).

### 8.4 Planning
- **ReAct-style** — model thinks, acts, observes, repeats (the default in modern function-calling models).
- **Explicit planners** — SK's older Handlebars/Function-Calling/Stepwise planners (largely superseded by native tool-calling).
- **Workflows** — MAF graph-based execution.

### 8.5 Observability
- OpenTelemetry traces for each model + tool call (`Microsoft.Extensions.AI` and MAF emit these natively).
- Token counts + cost per request.
- Evaluations (offline test sets scored by metrics — groundedness, relevance, fluency, safety).

---

## 9. Designing an Agent — A Checklist

Before any code, answer:

1. **Goal**: one sentence describing what the agent achieves.
2. **Tools**: minimal set of functions it needs. Fewer is better.
3. **Knowledge**: where does grounding data live? Vector store? Search? API?
4. **State**: what carries across turns? Where is it stored?
5. **Safety**: which operations need confirmation? Which are read-only?
6. **Identity**: whose credentials does each tool call use? (User vs system.)
7. **Eval**: a small set of golden tasks the agent must pass before each release.
8. **Observability**: traces, cost ceiling, alerting.
9. **Fallback**: what does the agent do when it gets stuck? Hand off to human? Apologise?
10. **Cost**: tokens per task × tasks per day × price.

Skipping any one of these is the difference between a demo and a product.

---

## 10. Common Pitfalls

| Pitfall | Why it bites | Mitigation |
|---|---|---|
| Too many tools | Model picks wrong one; latency up | Decompose into focused agents |
| Long instructions | Eats context window; model loses focus | Push detail into tool descriptions |
| No memory boundary | Cost explosion + privacy leak | Summarise or window aggressively |
| Mixing read/write in one agent without HITL | Real-world damage from a hallucination | Confirmation gates for writes |
| Ignoring tool errors | Agent loops forever | Return structured errors; let model react |
| No evals | Silent regressions on model swap | Golden tests + offline eval pipeline |
| Letting agents call agents indefinitely | Cost blowup, infinite loops | Iteration caps in workflow runtime |
| Storing PII in chat history forever | Compliance violation | TTL + redaction filters |
| One mega-agent for the whole company | Brittle; impossible to evaluate | Many small agents, each well-scoped |

---

## 11. Mental Model

> The framework is the **runtime**: a loop that turns the model's intent into tool calls and back. SK and MAF differ in ergonomics, not in fundamentals — both give you tools, memory, and orchestration. Start single-agent in SK or MAF, add a second agent only when the first one's prompt is doing two unrelated jobs.

---

## 12. Further Reading (for the curious)

- `Microsoft.SemanticKernel` API docs.
- `Microsoft.Agents.AI` (Microsoft Agent Framework) repo.
- `Microsoft.Extensions.AI` — the common abstraction for chat clients & function calling used under both SK and MAF.
- AutoGen documentation and examples.
- Azure AI Foundry — managed agent service docs.
- MCP (Model Context Protocol) specification.

Move to [Practice Problems](./Practice-Problems.md).
