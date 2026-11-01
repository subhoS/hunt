# Authorization Briefing — <program name>

**Fill this file before every campaign. The orchestrator renders it into
`<out_dir>/authorization-briefing.md` and every specialist reads it first.**

## Legal basis

- Program: <e.g. "Settle Vulnerability Disclosure Program (Bugcrowd, public VDP)">
- Scope URL: <link to scope page>
- Status: <"Active, ends YYYY-MM-DD" / "Private engagement, contract #..." / "Internal, by owner">
- Safe harbor: <quote the exact safe-harbor clause, or "none; written contract applies">
- Researcher: <email of record>

## In-scope — primary (test here)

- <host-1>  <notes: web app / API / self-serve signup / etc.>
- <host-2>

## In-scope — confirm-only (do NOT primary-test; only re-verify sandbox-proven findings)

- <host>

## In-scope — other (lower priority)

- <host>

## Out of scope — do not touch

- <host or class>

## Rules of engagement (hard constraints — specialists enforce)

1. No DoS. No stress testing. No high-volume automated scanning.
2. Volume cap: ≤ <N> req/s per host, ≤ <M> total per probe.
3. No data exfiltration beyond minimum PoC. Stop immediately on real PII.
4. Test accounts only. Register your own; never touch a real user.
5. Sandbox first; production only to confirm.
6. No social engineering. No physical attacks.
7. No publication until <program> confirms & remediates.
8. Record every finding with full evidence per <program>'s submission schema.

## Known-fruitful classes (hints, not facts)

<optional: patterns from recent disclosed reports on this program>

## Submission channel

<e.g. "Bugcrowd — https://bugcrowd.com/engagements/...">

## Notes for the swarm

<any program-specific quirks: required headers, researcher tag, test-account
seeding script, special billing identifier, etc.>
