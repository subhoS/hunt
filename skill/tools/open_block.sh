#!/usr/bin/env bash
# open_block.sh — record a block the specialist cannot resolve inside RoE.
#
# Usage:
#   open_block.sh <out_dir> <specialist> <finding_id> <context> <need> <suggest>
#
# Writes <out_dir>/blocks/<ts>-<uuid>.json. The orchestrator surfaces
# blocks to the user at the end of the exploit phase and asks how to
# proceed. Blocks are NEVER auto-resolved; a human decides.
set -euo pipefail

if [[ $# -ne 6 ]]; then
  echo "usage: $0 <out_dir> <specialist> <finding_id> <context> <need> <suggest>" >&2
  exit 2
fi

out_dir="$1"; specialist="$2"; finding_id="$3"; context="$4"; need="$5"; suggest="$6"

mkdir -p "$out_dir/blocks"
ts="$(date -u +%FT%TZ)"
id="$(uuidgen 2>/dev/null || date +%s%N)"
path="$out_dir/blocks/${ts}-${id}.json"

jq -n \
  --arg ts "$ts" \
  --arg specialist "$specialist" \
  --arg finding_id "$finding_id" \
  --arg context "$context" \
  --arg need "$need" \
  --arg suggest "$suggest" \
  '{ts:$ts,specialist:$specialist,finding_id:$finding_id,
    context:$context,need:$need,suggest:$suggest}' \
  > "$path"

echo "opened block: $path"
