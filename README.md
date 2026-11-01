# hunt — Autonomous Pentest Skill for Claude Code

A Claude Code skill that turns Claude into an autonomous penetration tester.
Point it at a target, step back, read the report.

```
/hunt example.com
/hunt https://staging.foo.com --objective "find RCE"
/hunt 10.0.0.5 --scope 10.0.0.0/24 --max-cycles 8
```

That's it. No mid-run prompts. No confirmations. No scope wizard.

## What's inside

Six Claude Code subagents + one slash command, all native to the Claude Code
interface. No external binary to install, no API keys beyond what Claude Code
already uses.

| Agent | Role | Model |
|---|---|---|
| `pentest-orchestrator` | ReAct loop; spawns the others; stops when a verified high/crit lands | Opus 4.7 |
| `pentest-recon` | Subdomains, ports, HTTP, tech, endpoints, API routes | Opus 4.7 |
| `pentest-classifier` | CVE/CVSS/severity/FP scoring, chain candidates | Opus 4.7 |
| `pentest-exploit` | Executes attack chains with evidence capture (SQLi/IDOR/BOLA/SSRF/SSTI/XXE/JWT/race/GraphQL) | Opus 4.7 |
| `pentest-verify` | Independent oracle re-run; VERIFIED / UNCONFIRMED / FALSE_POSITIVE | Opus 4.7 |
| `pentest-report` | Markdown + JSON + optional SARIF with OWASP/CWE/MITRE tags | Sonnet 5.5 |
| `/hunt` | Slash command entrypoint — target in, report out | — |

Opus 4.7 does every offensive step. Sonnet 5.5 only touches report prose
because long narrative on Opus burns tokens for no quality gain.

## Install

```bash
./install.sh
```

Or by hand — copy the `skill/` directory contents into
`~/.claude/skills/hunt/`:

```bash
mkdir -p ~/.claude/skills/hunt
cp -r skill/* ~/.claude/skills/hunt/
```

Then restart Claude Code (or `/reload`) and `/hunt` is available.

## How it runs

The orchestrator fans out:

```
recon ─▶ classifier ─▶ exploit ─▶ verify ─▶ report
  │          │           │          │          │
  │          │           │          │          └─ markdown + json + sarif
  │          │           │          └── per-category oracle, parallel per finding
  │          │           └── httpreq + jwt forging + evidence log
  │          └── CVE/CVSS, FP filter, chain candidates
  └── toolbelt probe + domain/URL/IP/CIDR plan
```

Loops recon→classify→exploit→verify until any one of:

1. ≥ 1 **VERIFIED** finding at CVSS ≥ 7
2. `max_cycles` reached (default 5)
3. Scope exhausted
4. User sends an explicit abort

Then the report writes a Markdown + JSON report (and SARIF if `--sarif` was
passed) with executive summary, kill-chain narrative, per-finding writeups
(OWASP/CWE/MITRE), and remediation.

## Attack coverage

Baked into the exploit agent's recipe library:

- **Injection**: SQLi (boolean / time), NoSQL (`$ne`, `$gt`), LDAP, XPath,
  Command, SSTI (Jinja/Twig/FreeMarker), XXE
- **Access control**: IDOR / BOLA (UUID / hashid / numeric / GraphQL node),
  BFLA (vertical privesc), mass assignment, path traversal / LFI
- **Server-side**: SSRF (internal + cloud-metadata chain → AWS creds),
  deserialization probing
- **Auth**: JWT alg:none, HMAC weak-secret bruteforce, auth-bypass header
  tricks (`X-Original-URL`, `X-Rewrite-URL`, `X-Forwarded-For`)
- **Client**: XSS (reflected + stored, headless-verified where possible),
  open redirect, CORS misconfig
- **GraphQL**: introspection + alias batching + node-id IDOR
- **Business logic**: race conditions (`--race N` fan-out), coupon redemption,
  single-use token abuse
- **Infra**: nuclei templates (critical/high/medium) wrapped in the pipeline

Each recipe has an **EVIDENCE criterion** — findings only ship when the
response matches it. "The server responded" is not evidence.

## Operational floor

The exploit agent has a quiet blocklist on patently self-destructive shell
commands (`rm -rf /`, `mkfs`, `dd of=/dev/`, `shutdown`, `curl … | sh`,
`chmod -R 777 /`, fork bombs, `kill -9 1`). These aren't offensive-security
payloads; they're footguns on your own machine. If an LLM gets confused mid-
run, this stops it from `rm -rf`-ing your home dir. Nothing else is filtered.

If you want this gone too, delete the "operational floor" block from
`agents/pentest-exploit.md` and `agents/pentest-orchestrator.md`.

## Output

Every run writes to `./reports/campaign-YYYYMMDD-HHMMSS-<id>/`:

```
campaign.json              # per-cycle state + final report pointers
surface.json               # recon output
classified_findings.json   # ranked findings
execution_results.json     # exploit evidence
verify-<id>.json           # one per verified finding
report-<id>.md             # the deliverable
report.json                # structured mirror
report.sarif               # optional
req-*.body req-*.hdr       # raw request/response captures
```

## Tool availability

The recon agent self-probes its toolbelt (`subfinder`, `dnsx`, `naabu`,
`httpx`, `nuclei`, `katana`, `gau`, `dalfox`, `sqlmap`, `nikto`, `ffuf`,
`nmap`). Missing tools are not fatal — the agent falls back to `curl` +
`crt.sh` + `dig` for passive enumeration. For best signal, install the
ProjectDiscovery suite:

```bash
# macOS
brew install projectdiscovery/tap/subfinder projectdiscovery/tap/dnsx \
             projectdiscovery/tap/naabu projectdiscovery/tap/httpx \
             projectdiscovery/tap/nuclei projectdiscovery/tap/katana
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/hahwul/dalfox/v2@latest
brew install nikto ffuf sqlmap
```

## License

MIT. Use responsibly. You own what you point this at.
