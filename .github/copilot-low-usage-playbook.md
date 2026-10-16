# Copilot Low-Usage Playbook

Use this page to reduce Copilot credit/token burn while keeping output quality high.

For this workspace, pair this playbook with [.github/copilot-instructions.md](.github/copilot-instructions.md) and [.github/project-config.md](.github/project-config.md).

## Core defaults

- Use standard ask/edit prompts for most work.
- Use agent mode only when the task clearly spans 3 or more files, or needs repeated search/edit/validate loops.
- Keep prompts short and scoped to one outcome.
- Include only the minimum relevant context and only the file(s) that matter.
- Ask for concise output first, expand only if the first answer is not enough.
- If a task grows beyond 6 steps or needs broad refactoring, stop and ask before continuing.

## Decision rules

### Use normal chat for

- Single-file fixes.
- Explanations and quick code questions.
- Refactors within one function or one module.
- Small test updates.

### Use agent mode for

- Cross-file changes in 3 or more files.
- Tasks requiring code search, edits, and validation loops.
- Workflows that need tooling orchestration.

### Stop condition for agent prompts

Add this line in your prompt:

```text
If this requires more than 6 steps or broad refactors, stop and ask me before continuing.
```

## FireWatch Prompt Pattern

Use this template when asking for repo work:

```text
Goal: [one sentence]
Scope: [specific file or function]
Constraints: [no broad refactors, no unrelated files]
Context: [20-60 relevant lines only]
Output: [minimal diff or direct answer]
```

Prefer this project context order when relevant:

1. `.github/project-config.md`
2. `PRD.md`
3. `PLAN.md`

## Prompt templates

### Template A: Focused question

```text
Goal: [one sentence]
Scope: [file/function only]
Constraints: [max 8 lines, no alternatives]
Context: [20-60 relevant lines]
Output: [direct answer only]
```

### Template B: Minimal code edit

```text
Change requested: [specific behavior]
File: [path]
Allowed edits: [function/class only]
Do not: [no renames, no unrelated formatting]
Return: [minimal diff + 2-line rationale]
```

### Template C: Debugging

```text
Error: [exact message]
Repro: [short numbered steps]
Suspected file: [path]
Request: [root cause first, then smallest fix]
```

## Context budget rules

- Do not paste entire files unless strictly required.
- Share only the failing section, plus nearby definitions.
- Avoid long historical chat context for new topics.
- Start a fresh chat when switching tasks.

## High-burn features to use carefully

- Frequent code review runs on large pull requests.
- Frontier/high-multiplier models for routine tasks.
- Long autonomous sessions with many follow-up prompts.

## Personal operating checklist

Before sending a prompt, check:

- Is this one clearly scoped task?
- Did I provide only required context?
- Did I ask for concise output first?
- Do I really need agent mode here?

## Weekly usage hygiene

- Review usage dashboard once per week.
- Identify highest-burn workflows and tighten prompts.
- Keep one default low-cost model for routine work.
- Reserve advanced models for hard tasks only.

## Example low-usage prompt

```text
Fix one bug in send policy logic.
Scope: docs/send-policy.md only.
Return a minimal patch and a 3-line explanation.
Do not change unrelated wording.
If broader cleanup is needed, stop and ask.
```
