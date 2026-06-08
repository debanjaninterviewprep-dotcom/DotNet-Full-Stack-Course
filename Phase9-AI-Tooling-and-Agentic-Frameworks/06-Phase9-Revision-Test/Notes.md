# Topic 6: Phase 9 Revision Test

## About This Test

A **comprehensive revision test** covering all 5 topics of Phase 9: AI Tooling & Microsoft Agentic Frameworks. Designed to confirm you can pick the right Copilot surface, extend M365 with declarative agents and plugins, build single- and multi-agent systems in SK / MAF, use AI safely in PR review and testing, and wire AI helpers into CI/CD without trusting them blindly.

**Rules:**
- Solve every problem without re-reading earlier notes.
- Target time: 4–5 hours.
- Production-quality code where code is required. OAuth/OIDC, structured outputs, evals.
- After finishing, tell me **"check"** for a graded review.

---

## Section A: Quick-Fire Concepts (12 questions)

Answer each in 1–3 sentences. Write into `Section-A.md`.

1. Difference between **GitHub Copilot** and **Microsoft 365 Copilot**.
2. What is `.github/copilot-instructions.md` and what does an `applyTo:` instruction file add?
3. When should you choose a **Graph connector** over a **declarative agent + plugin**?
4. Why must API plugin OpenAPI operations have rich `description` strings?
5. Why is **Microsoft Agent Framework** different from **Semantic Kernel** — give one capability MAF adds.
6. Define **AgentThread** and why it matters for production agents.
7. What's the difference between **ReAct-style** planning and an **explicit planner**?
8. What does **mutation testing** measure that coverage doesn't?
9. Why is "generate tests after writing the code" a weaker signal than TDD with AI?
10. One concrete risk of running an **MCP server** in CI with broad credentials.
11. Why should AI **never** auto-apply Terraform changes to prod?
12. What does **structured JSON output** buy you when an agent posts to a Teams incident channel?

---

## Section B: Architecture & Diagrams (3 questions)

Use Mermaid. Write into `Section-B.md`.

### B1 — Pick-a-framework flowchart
Draw a decision flowchart that selects between **Copilot Studio**, **Declarative Agent**, **Semantic Kernel**, **Microsoft Agent Framework**, **Azure AI Foundry Agent Service**, **AutoGen**, **Bot Framework SDK**. Each leaf should answer "use X because Y".

### B2 — Multi-agent workflow
Draw a 3-agent workflow for "draft and validate a release note from a PR diff": Summariser → Editor → Validator, with a manager controlling iterations and a budget guard.

### B3 — AI-augmented CI/CD pipeline (300 words)
Draw and describe a CI/CD pipeline for TaskFlow that uses AI in: PR description, code review, log triage, terraform-plan review, cost review, and incident triage — while keeping **the final apply on prod entirely under human control**. Annotate every AI hop with the model used and the guardrail.

---

## Section C: Code Reading (4 questions)

Identify the bugs and write a corrected version. Save as `Section-C.md`.

### C1 — Declarative Agent + Plugin
```json
{
  "name": "TaskFlow",
  "description": "Helps with TaskFlow",
  "instructions": "Be helpful.",
  "conversation_starters": [{"text":"hi"}],
  "actions": [{"id":"taskflow","file":"plugin.json"}]
}
```
And plugin.json:
```json
{
  "name_for_human": "TF",
  "description_for_model": "Tasks API",
  "functions": [{"name":"do_stuff"}],
  "runtimes": [{"type":"OpenApi","auth":{"type":"None"},"spec":{"url":"openapi.yaml"}}]
}
```

### C2 — SK Agent
```csharp
var agent = new ChatCompletionAgent
{
    Instructions = "Help the user.",
    Kernel = kernel
};
chat.AddUserMessage("Delete project TF-2031");
await foreach (var m in agent.InvokeAsync(chat))
    Console.WriteLine(m);
```
(Plus a plugin with `DeleteProjectAsync` that has `[KernelFunction]` and `[Description("Delete a project.")]`.)

### C3 — Test generation
```csharp
[Fact]
public async Task GetOverdueTasks_works()
{
    var result = await _service.GetOverdueAsync("TF-2031");
    Assert.NotNull(result);
}
```

### C4 — CI workflow
```yaml
on: [push, pull_request]
permissions: write-all
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@main
      - run: dotnet test
      - uses: azure/login@v1
        with: { creds: ${{ secrets.AZURE_CREDENTIALS }} }
      - run: az webapp deploy ...
```

---

## Section D: Hands-On Build (Pick 2 of 3)

Build two of these end-to-end. Code in `Section-D/`.

### D1 — Declarative Agent + API Plugin for TaskFlow

Build:
- Declarative agent with clear instructions, 5 conversation starters, SharePoint knowledge source.
- API plugin with 4 operations: 3 reads + 1 write (with confirmation card).
- Entra OAuth wired; scopes documented.
- Sideloaded to a tenant/sandbox; screenshots of read and write conversations.

### D2 — Multi-Agent Release-Note Workflow in MAF

Build:
- 3 agents (Summariser / Editor / Validator) in `Microsoft.Agents.AI`.
- Group-chat workflow with iteration cap and budget guard.
- Input: a real Git diff.
- Output: final release note + transcript.
- Eval: feed 3 different diffs, score validator correctness.

### D3 — AI-Augmented CI Pipeline

Build:
- GH Actions workflow with: build/test, **AI log triage on failure**, **AI Terraform-plan reviewer**, **AI cost reviewer** posting structured PR comments.
- Each AI step uses a composite action and structured prompts (JSON output).
- Demonstrate one PR that triggers all three AI steps; capture comments.
- Audit log of every prompt + response stored as an artifact.

---

## Section E: Cost, Safety, Governance (3 questions)

Save as `Section-E.md`.

### E1 — Cost
A TaskFlow support agent serves 800 conversations/day, averaging 6 turns each, with input tokens ~1.5k and output tokens ~400 per turn. Compute the daily and monthly cost on `gpt-4o` vs `gpt-4o-mini`, then design an eval set (5 prompts max) you'd run before switching to the cheaper model.

### E2 — Safety
Walk through your safety design for a write-capable Copilot agent (one that can update tasks, send emails, and create calendar entries on behalf of users). Cover: identity, scopes, confirmation gates, audit log, rate limit, prompt-injection mitigations, and the kill switch.

### E3 — Governance
Tenant admins want to allow exactly 3 plugins and block all others. Describe how you'd enforce this technically and operationally (admin centre, content exclusions, monitoring, exception process).

---

## Section F: Security Audit (2 questions)

### F1 — Mark Pass / Fail / Needs work + 1-sentence reason

Save as `Section-F.md`.

- [ ] Copilot tier is Business+ for any commercial repo.
- [ ] `copilot-instructions.md` says what NOT to do (forbidden libs, patterns).
- [ ] All API plugins require Entra OAuth (no anonymous).
- [ ] Write operations in plugins gated by confirmation cards.
- [ ] Graph-connector ACLs match Entra group membership and are refreshed.
- [ ] PR template includes "Why" + "Risk" + "Tests" sections.
- [ ] Path-scoped instructions exist for controllers and migrations.
- [ ] Mutation testing run on new files in CI.
- [ ] AI-generated tests reviewed by a human before merge.
- [ ] CI workflows use OIDC for Azure login; no static `AZURE_CREDENTIALS` JSON.
- [ ] Every AI step in CI pins the action by SHA.
- [ ] AI agents in CI use scoped, read-only credentials where possible.
- [ ] MCP servers (if any) run with least privilege and are version-pinned.
- [ ] AI-suggested Terraform changes never auto-apply to prod.
- [ ] Triage agents output structured JSON validated before being posted to Teams.

### F2 — Pick the **three most dangerous** failures from F1 and write a remediation plan (steps + commands).

---

## Submission

Tell me **"check"** when finished. I will:
- Score each section 0–10 (B-section 0–6 each) with detailed feedback.
- Identify weakest areas to revisit before Phase 10.

Total: **100**. Passing: **70**.
