---
name: hunt
description: >-
  Autonomous end-to-end penetration test. Point it at a target (domain, IP, URL,
  CIDR) and it runs the full recon → classify → exploit → verify → report cycle
  with no mid-run prompts and no confirmations. Loops until a verified high/
  critical finding or max_cycles is reached, then writes a professional report.
  Invoke by name or via /hunt. Uses Opus 4.7 for every offensive agent and
  Sonnet 5.5 only for report curation.
---

# hunt — Autonomous Pentest Skill

Give it a target. It runs. No questions.

## What it does

When the user says anything like:

- `/hunt example.com`
- `hunt api.target.io`
- `pentest 10.0.0.5`
- `find exploits on https://staging.foo.com`
- `go after acme.corp`

delegate immediately to the `pentest-orchestrator` subagent via the `Agent`
tool. The orchestrator fans out to the five specialists and loops the attack
cycle until a verified finding at CVSS ≥ 7 lands or `max_cycles` is reached.

You do NOT run the attack yourself. You hand off and surface the report.

## Model pinning (non-negotiable)

Every offensive agent runs on **Opus 4.7** (`claude-opus-4-7`). The report
writer runs on Sonnet 5.5 to save tokens on the long narrative — nothing else
should ever use a non-Opus model.

| Agent | Model |
|---|---|
| pentest-orchestrator | claude-opus-4-7 |
| pentest-recon | claude-opus-4-7 |
| pentest-classifier | claude-opus-4-7 |
| pentest-exploit | claude-opus-4-7 |
| pentest-verify | claude-opus-4-7 |
| pentest-report | claude-sonnet-5-5 |

The frontmatter on each agent file already carries this. Do not override.

## Call shape

```
Agent({
  subagent_type: "pentest-orchestrator",
  description: "Autonomous pentest of <TARGET>",
  prompt: """
    target:     <TARGET>
    objective:  <"find any exploitable vulnerability" unless the user named one>
    scope:      <TARGET and *.TARGET when TARGET is a bare domain; the TARGET itself otherwise>
    safe_mode:  false
    max_cycles: 5

    Run end-to-end. Do not stop for confirmations. Chain findings on success.
    Never fabricate findings. Return the report path when done.
  """
})
```

Parse the user's message for optional flags: `--objective "..."`, `--scope
"a,b,c"`, `--safe-mode=true` (default **false**), `--max-cycles N` (default 5).
Nothing is required but the target.

## While it runs

The orchestrator is a background agent. Do not peek at its transcript. When
the completion notification arrives, surface the final-user-message block
verbatim and attach the Markdown report with `SendUserFile` so the user sees
it on whatever device they're on.

If the user sends a mid-task message, keep driving unless they explicitly say
pause / abort / redirect, in which case forward to the orchestrator via
`SendMessage` to its session id.

## Shape

Everything lives under this skill directory:

- `SKILL.md` — this file
- `agents/pentest-orchestrator.md` — top-level ReAct driver
- `agents/pentest-recon.md` — attack-surface mapping
- `agents/pentest-classifier.md` — CVE/CVSS/severity scoring
- `agents/pentest-exploit.md` — attack chains + evidence capture
- `agents/pentest-verify.md` — independent oracle re-run
- `agents/pentest-report.md` — Markdown + JSON report generation
- `commands/hunt.md` — `/hunt` slash command entrypoint

Install with `install.sh` or copy the contents into `~/.claude/skills/hunt/`.
