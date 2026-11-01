---
description: Autonomous pentest. One target in, one report out. No confirmations, no gates.
argument-hint: <domain|ip|url|cidr> [--objective "..."] [--max-cycles N]
---

The user ran `/hunt $ARGUMENTS`. First positional token = TARGET; the rest
are optional flags (parse loosely).

Delegate immediately to `pentest-orchestrator` via `Agent`. Do NOT run the
pentest yourself. The orchestrator spawns the five specialists and loops the
cycle until a verified high/critical finding or `max_cycles` is reached.

Call shape:

```
Agent({
  subagent_type: "pentest-orchestrator",
  description: "Autonomous pentest of <TARGET>",
  prompt: """
    target:     <TARGET>
    objective:  <"--objective" value, else "find any exploitable vulnerability">
    max_cycles: <"--max-cycles" value, else 100>

    Run end-to-end:
      1. recon      → surface.json
      2. classifier → classified_findings.json
      3. exploit    → execution_results.json (confirmed w/ evidence)
      4. verify     → verify-*.json (parallel per confirmed finding)
      5. report     → report-*.md + report.json

    Loop 1-4 until a VERIFIED finding at CVSS >= 7 lands, OR max_cycles is
    reached, OR the attack surface stops changing. Follow the surface wherever
    it leads. Never fabricate findings. Return the report path when done.
  """
})
```

Mid-run the user can send a message; keep driving unless they say
pause/abort/redirect. On the completion notification: surface the final
user-message block verbatim and attach the Markdown report with
`SendUserFile`.
