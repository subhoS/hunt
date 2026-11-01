#!/usr/bin/env bash
# Install the hunt skill into Claude Code's user-level directories.
#   skill files        → ~/.claude/skills/hunt/
#   subagent definitions → ~/.claude/agents/     (Claude Code resolves subagent_type here)
set -euo pipefail

SKILL_SRC="$(cd "$(dirname "$0")/skill" && pwd)"
SKILL_DST="${HOME}/.claude/skills/hunt"
AGENTS_DST="${HOME}/.claude/agents"

echo "installing hunt skill → $SKILL_DST"
mkdir -p "$SKILL_DST"
cp -R "$SKILL_SRC/." "$SKILL_DST/"

echo "installing subagents → $AGENTS_DST"
mkdir -p "$AGENTS_DST"
for f in "$SKILL_SRC"/agents/*.md; do
  base="$(basename "$f")"
  dst="$AGENTS_DST/$base"
  if [[ -e "$dst" ]] && ! cmp -s "$f" "$dst"; then
    echo "  ! $base already exists and differs — backing up to ${base}.bak"
    cp "$dst" "${dst}.bak"
  fi
  cp "$f" "$dst"
done

echo
echo "✓ installed"
echo
echo "Agents and the /hunt slash command are now available in Claude Code."
echo "Restart Claude Code (or start a new session) so the new subagents are picked up."
echo "Try:  /hunt example.com"
echo
echo "Models: Opus 4.7 for every offensive agent, Sonnet 5.5 for the report writer."
