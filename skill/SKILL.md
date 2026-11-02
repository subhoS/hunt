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
    max_cycles: 100

    Run end-to-end. Do not stop for confirmations. Chain findings on success.
    Follow the attack surface wherever it leads. Never fabricate findings.
    Return the report path when done.
  """
})
```

Parse the user's message for optional flags: `--objective "..."`,
`--max-cycles N` (default 100 — effectively "work until you land one").
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
- `agents/pentest-exploit.md` — single-threaded attack chains + evidence (Mode A)
- `agents/pentest-auth-session.md` — A6: auth, session, JWT, OAuth, 2FA, reset
- `agents/pentest-access-idor.md` — A6: IDOR, mass assignment, tenant isolation, GraphQL authz
- `agents/pentest-injection.md` — A6: SQLi / NoSQLi / SSTI / cmdi / XXE / LDAP / header / proto-pollution
- `agents/pentest-business-logic.md` — A6: workflow, state, pricing, discounts, idempotency gaps
- `agents/pentest-ssrf-cloud.md` — A6: SSRF, open redirect, URL schemes, cloud metadata, webhook abuse
- `agents/pentest-race-toctou.md` — A6: parallel-request abuse, double-spend, TOCTOU
- `agents/pentest-verify.md` — independent oracle re-run
- `agents/pentest-report.md` — Markdown + JSON report generation
- `templates/authorization-briefing.md` — scope + RoE template rendered per campaign
- `references/attack-conventions.md` — guard-reporter + pause-and-ask + evidence protocol
- `tools/log_guard.sh` — append structured guard observation to `guards.jsonl`
- `tools/open_block.sh` — open a human-review block under `blocks/`
- `commands/hunt.md` — `/hunt` slash command entrypoint

Install with `install.sh` (copies the skill tree AND wires every agent
into `~/.claude/agents/`), then restart Claude Code.

## Exploit modes

The orchestrator picks per campaign based on classified findings:

- **Mode A** (small surface): single `pentest-exploit`, same as before.
- **Mode A6** (≥ 3 classes AND ≥ 6 findings): six specialists in parallel,
  each on their class bucket. Classes map to specialists via
  `agents/pentest-orchestrator.md` → "Attack-class → specialist mapping".

Each specialist is a leaf (no further Agent spawning), pinned to Opus
4.7, bound to the same RoE through the authorization briefing.

## Guard reporter and pause-and-ask

The swarm does NOT auto-bypass defenses. When a specialist's probe hits
a WAF, rate limit, auth wall, captcha, account lock, scope boundary, or
the harness's own classifier, it writes a structured entry to
`<out_dir>/guards.jsonl` via `tools/log_guard.sh` and moves on. When a
specialist needs to do something it cannot do inside RoE, it opens a
block via `tools/open_block.sh` under `<out_dir>/blocks/` and marks the
finding `blocked_need_human: true`. The orchestrator surfaces every open
block at the phase boundary and asks the user how to proceed. Blocks are
never auto-resolved. Full protocol: `references/attack-conventions.md`.

## Authorization briefing

The invoker (slash command / user prompt / orchestrator caller) supplies
scope + RoE + legal basis. The orchestrator renders
`<out_dir>/authorization-briefing.md` from
`templates/authorization-briefing.md` and that file is read FIRST by
every specialist. It is also the context Claude Code's harness classifier
needs to clear a "third-party attack" check on each spawn. If the
briefing cannot be filled, the orchestrator does not spawn; it writes a
block and surfaces to the user.

## Video POC capture (mandatory)

Every VERIFIED finding ships with a visual POC alongside the HTTP
evidence — a short GIF/screencast of the exploit running end-to-end on
the sandbox. VDP programs (Bugcrowd, HackerOne, direct) triage
video-backed reports faster and at the correct severity because the
proof is self-contained. Operator preference: capture every submission
with a video.

The hunt subagents cannot do this — their toolset is Bash / Read /
Write / Grep / Glob / WebFetch, no browser-GIF capability. So the
orchestrator records a *capture queue* into
`<out_dir>/video_capture_todo.md` listing each VERIFIED finding with its
repro command, target URL, and expected proof signal; the MAIN invoking
session (which has `mcp__Claude_Browser__*` or
`mcp__claude-in-chrome__gif_creator`) picks up that queue after the
orchestrator returns and captures `poc-<finding_id>.gif` / `.mp4`
into the campaign dir. The report writer scans for those files and
embeds references automatically. See
`references/attack-conventions.md` → "Video POC capture" for the full
protocol and the no-PII rules.
