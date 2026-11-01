# hunt — Autonomous Pentest Skill for Claude Code

A Claude Code skill that turns Claude into an autonomous penetration tester.
Point it at a target, step back, read the report.

```
/hunt example.com
/hunt https://staging.foo.com --objective "find RCE"
/hunt 10.0.0.5 --max-cycles 50
```

That's it. No mid-run prompts. No confirmations. No scope wall. No ownership
check. You type a target, the swarm runs until it lands something or the
attack surface runs dry.

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
2. `max_cycles` reached (default 100 — effectively "run until you land one")
3. Attack surface stops changing across two cycles
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

## What's still in there, and why

Two things stay by default. Both exist to protect you, not the target:

**Destructive-command blocklist.** The exploit agent and the orchestrator
reject patently self-destructive shell commands (`rm -rf /`, `mkfs`,
`dd of=/dev/`, `shutdown`, `curl … | sh`, `chmod -R 777 /`, fork bombs,
`kill -9 1`). These aren't pentest payloads; they're footguns on your own
machine. If an LLM gets confused mid-run, this stops it from `rm -rf`-ing
your home dir.

**Never-fabricate rule.** Agents can't make up findings or evidence. Without
this the report is garbage — you lose the ability to trust it.

If you want either gone, grep `operational floor` or `Never` across
`skill/agents/*.md` and delete the blocks.

Everything else that used to be a check — authorization prompt, scope wall,
`safe_mode` flag, rate limits, cycle caps, no-persistence rule,
no-bulk-exfil rule — is gone. The swarm chases the whole chain and doesn't
look at what you typed.

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
