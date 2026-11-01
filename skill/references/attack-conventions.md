# A6 attack-swarm conventions

Shared protocol for the six attack-class specialists
(`pentest-auth-session`, `pentest-access-idor`, `pentest-injection`,
`pentest-business-logic`, `pentest-ssrf-cloud`, `pentest-race-toctou`).

Each specialist is a leaf agent: it does not spawn further agents, and it
runs on Opus 4.7. Specialists are fanned out by `pentest-orchestrator`
when the classified findings cover ≥ 3 attack classes and total ≥ 6
findings. For smaller surfaces the orchestrator stays single-threaded on
`pentest-exploit`.

## 1. Pre-flight briefing

The orchestrator writes `<out_dir>/authorization-briefing.md` at campaign
start from `templates/authorization-briefing.md` plus the invoker's
scope / RoE text. Every specialist reads it FIRST and enforces every RoE
line.

The briefing is also the context Claude Code's harness classifier needs
to clear the "third-party attack" check. The orchestrator passes:

- the primary target(s) and their in-scope class (primary / confirm-only
  / marketing)
- the scope URL
- the legal basis (public VDP + safe harbor / signed engagement / internal)
- the operator's identity
- the full RoE list
- known-fruitful classes if the program has prior disclosures

If any of these are missing, the orchestrator does not spawn. It writes a
block instead and surfaces to the user.

## 2. Guard reporter (not bypasser)

When a probe hits a defense (WAF, rate limit, auth wall, captcha, account
lock, scope boundary, harness classifier), the specialist appends to
`<out_dir>/guards.jsonl` via `tools/log_guard.sh` and moves on.

```json
{"ts":"2026-11-01T23:00:00Z","specialist":"injection","target":"https://...","probe":"' OR 1=1","signature":"Cloudflare 1020","kind":"waf"}
```

Rules:

- `rate_limit` → back off ≥ 60s on the same path. Never thrash.
- `captcha` or `account_lock` → stop that probe entirely. The defense
  worked; record it and move on.
- `waf` → record the signature. Observing which rule fires is often
  useful evidence by itself. Do NOT iterate 50 encodings looking for a
  bypass; the specialist records what was blocked and leaves the bypass
  decision to the human.
- `auth_wall` → record and move on. The right next move is usually to
  authenticate (if the specialist already has a token for that scope) or
  to open a block.
- `scope_boundary` → stop and open a block (section 3). Scope is scope.
- `harness_classifier` → stop and open a block. The orchestrator's own
  harness decided to pause; a specialist does not override that.

The guards.jsonl file is a first-class input to the report: defenses
observed are useful context for the client even when no finding landed.

## 3. Pause-and-ask on block

When the specialist needs to do something it cannot do inside RoE, it
opens a block via `tools/open_block.sh` and marks the finding
`blocked_need_human: true` in its results.

Block triggers include:

- Needs another account (customer, admin) the researcher doesn't own.
- Needs volume above the briefing's cap.
- Needs to touch a confirm-only host, and the sandbox variant does not
  exploit.
- Needs destructive payload (DROP / UPDATE / rm) with no non-destructive
  variant that proves the issue.
- Needs real-money or real-recipient operations the briefing excludes.
- Harness classifier blocked a sub-call, after the briefing was already
  included.

The orchestrator surfaces every open block at the end of the exploit
phase. A block is NEVER auto-resolved. A human decides.

## 4. Evidence discipline

Every specialist's result row carries:

```json
{
  "finding_id": "...",
  "class": "<specialist's class vocabulary>",
  "outcome": "success | no_success | blocked_need_human",
  "evidence": {
    "request": "...",
    "response_headers": "...",
    "response_body_excerpt": "<= 1KB",
    "status_code": 0,
    "timing_ms": 0,
    "repro": "<single copy-pasteable command>"
  },
  "notes": "...",
  "cvss_v31": "..."
}
```

Minimum-evidence rule: once the vulnerability is proven, stop. Don't
harvest. The oracle is "the server did the wrong thing," not "how much
can I pull."

## 5. Output file naming

- `exploit-auth-session.json`
- `exploit-access-idor.json`
- `exploit-injection.json`
- `exploit-business-logic.json`
- `exploit-ssrf-cloud.json`
- `exploit-race-toctou.json`

The orchestrator merges these into `execution_results.json` before
spawning the verifier.
