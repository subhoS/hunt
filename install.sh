#!/usr/bin/env bash
# Install the hunt skill into Claude Code's user-level skills directory.
set -euo pipefail

SKILL_SRC="$(cd "$(dirname "$0")/skill" && pwd)"
SKILL_DST="${HOME}/.claude/skills/hunt"

echo "installing hunt skill → $SKILL_DST"
mkdir -p "$SKILL_DST"
cp -R "$SKILL_SRC/." "$SKILL_DST/"

echo
echo "✓ installed"
echo
echo "Agents and the /hunt slash command are now available in Claude Code."
echo "Try:  /hunt example.com"
echo
echo "Models: Opus 4.7 for every offensive agent, Sonnet 5.5 for the report writer."
