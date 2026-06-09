# Practice Problems — Microsoft Agentic Frameworks Overview

> Tell me **"check"** after finishing.

---

## P1 — Framework Selection Matrix

**Goal:** Build a decision aid your team can use.

**Tasks:**
- For each of the 8 scenarios below, pick a framework (SK / MAF / AutoGen / Copilot Studio / Foundry Agent Service / Declarative Agent / Bot Framework) and justify in ≤ 2 sentences.

1. HR team wants a no-code bot that answers leave-policy questions from SharePoint.
2. .NET API that takes a natural-language query and returns a JSON answer using a vector DB.
3. A 5-step financial closing workflow with planner + executor + auditor agents.
4. Adding "explain this dashboard" to a Power BI report.
5. A long-lived agent that needs persistent threads, file search, and code interpreter without you running infra.
6. Research prototype testing four different speaker-selection strategies.
7. Conversational ordering assistant deployable to Web Chat, Teams, and WhatsApp.
8. M365 Copilot Chat persona answering questions from TaskFlow's project library and triggering writes via an API.

**Deliverable:** `selection-matrix.md` with the choice + justification per scenario.

**Look-fors:** Defensible choices; clear when the cheaper option suffices.

---

## P2 — Single-Agent in Semantic Kernel

**Goal:** Build a working `ChatCompletionAgent` for TaskFlow with two tools and short-term memory.

**Tasks:**
1. .NET 8 console app.
2. Use `Microsoft.SemanticKernel` + Azure OpenAI (or OpenAI direct in dev).
3. Plugin `TaskFlowPlugin` with `GetOverdueTasksAsync` + `UpdateStatusAsync` (mock backend ok).
4. `ChatCompletionAgent` with clear instructions including "ask before any write".
5. Loop reading user input; print agent responses.
6. Demonstrate two real conversations (transcript saved): one read-only, one write-with-confirmation.

**Deliverable:** Source + `transcripts.md`.

**Look-fors:** `[KernelFunction]` descriptions are rich; confirmation actually gates the write; chat history sensibly managed.

---

## P3 — Same Agent in Microsoft Agent Framework

**Goal:** Re-implement P2 using `Microsoft.Agents.AI` to compare ergonomics.

**Tasks:**
1. New .NET 8 console app.
2. Use `AIAgent` + `AIFunctionFactory.Create(...)`.
3. Same tools as P2.
4. Use an `AgentThread` for state.
5. Side-by-side `comparison.md` covering: lines of code, observability, ergonomics, suitability.

**Deliverable:** Source + `comparison.md`.

**Look-fors:** Honest comparison; you note what MAF gives you (telemetry, thread abstraction) and what it costs (newer package, fewer docs).

---

## P4 — Multi-Agent Workflow in MAF

**Goal:** Build a 3-agent group chat that drafts a release note for a PR.

**Tasks:**
1. Agents: **Summariser** (reads diff, writes change summary), **Editor** (rewrites for tone), **Validator** (checks claims against the diff).
2. Use a group-chat manager with a max iteration count.
3. Input: a static `diff.txt`.
4. Output: a final markdown release note + a transcript of the conversation.
5. Add an iteration cap and a simple budget guard (e.g., abort if total tokens > 30k).

**Deliverable:** Source + `release-note.md` + `transcript.md`.

**Look-fors:** Cap enforced; validator actually rejects at least one bad claim; final note matches the diff.

---

## P5 — Memory Strategy Design

**Goal:** Design a memory strategy for a long-running customer-support agent.

**Tasks:** In `memory-strategy.md` answer:
1. What goes in short-term (chat history window size? summarisation? when?).
2. What goes in long-term (vector store of past resolutions? per-customer profile? PII handling?).
3. How retention / TTL is enforced.
4. How privacy controls (right to be forgotten) are implemented.
5. Estimated token cost per conversation under your design.

**Deliverable:** `memory-strategy.md` (~2 pages).

**Look-fors:** Cost math present; PII handled; not over-engineered.

---

## P6 — Evaluation Set

**Goal:** Build a small but useful golden set for your TaskFlow agent.

**Tasks:**
1. Write 12 prompts spanning happy path, ambiguous input, dangerous request, out-of-scope request, multi-tool plan.
2. For each, define the *expected behaviour* (not exact text). Categories: tool called, refusal, asked for clarification, etc.
3. Implement a simple eval runner (xUnit `[Theory]` or a console script) that runs each prompt and checks behaviour heuristically (tool call inspection from telemetry).
4. Define pass/fail thresholds.

**Deliverable:** `evals/` folder with runner + golden set + a baseline run report.

**Look-fors:** Tests catch realistic regressions; not just "asserts not null".

---

## P7 — Cost Model

**Goal:** Estimate annual cost for your TaskFlow agent.

**Tasks:** In `cost-model.md`:
- Average tokens per turn (input + output) for your agent class.
- Average turns per conversation.
- Conversations per day.
- Multiply, then add tool costs (API calls, vector queries).
- Compare against budgets for `gpt-4o`, `gpt-4o-mini`, and `gpt-4.1`.
- Recommend the cheapest model that still passes the eval set.

**Deliverable:** `cost-model.md` with numbers + recommendation.

**Look-fors:** Reasonable assumptions; you actually ran the eval on the cheap model.

---

## Scoring Rubric

| # | Pts | Full marks |
|---|---|---|
| P1 | 10 | Choices defensible |
| P2 | 15 | Working SK agent; confirmation gates work |
| P3 | 15 | MAF version; comparison honest |
| P4 | 20 | Multi-agent works; cap enforced |
| P5 | 10 | Privacy + cost addressed |
| P6 | 15 | Eval set is real; baseline measured |
| P7 | 15 | Numbers consistent; recommendation tied to evals |

Total: 100. Pass: 70.
