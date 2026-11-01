#!/usr/bin/env bash
# log_guard.sh — append a structured guard entry to <out_dir>/guards.jsonl.
#
# Usage:
#   log_guard.sh <out_dir> <specialist> <target> <probe> <signature> <kind>
#
# Kinds:
#   waf | rate_limit | auth_wall | captcha | account_lock
#   scope_boundary | harness_classifier
#
# This logs the defense observation. It does NOT bypass anything. Specialists
# that need to proceed past a scope_boundary or harness_classifier should
# call open_block.sh instead.
set -euo pipefail

if [[ $# -ne 6 ]]; then
  echo "usage: $0 <out_dir> <specialist> <target> <probe> <signature> <kind>" >&2
  exit 2
fi

out_dir="$1"; specialist="$2"; target="$3"; probe="$4"; signature="$5"; kind="$6"

case "$kind" in
  waf|rate_limit|auth_wall|captcha|account_lock|scope_boundary|harness_classifier) ;;
  *) echo "invalid kind: $kind" >&2; exit 2 ;;
esac

mkdir -p "$out_dir"
jq -nc \
  --arg ts "$(date -u +%FT%TZ)" \
  --arg specialist "$specialist" \
  --arg target "$target" \
  --arg probe "$probe" \
  --arg sig "$signature" \
  --arg kind "$kind" \
  '{ts:$ts,specialist:$specialist,target:$target,probe:$probe,signature:$sig,kind:$kind}' \
  >> "$out_dir/guards.jsonl"

echo "logged guard: kind=$kind specialist=$specialist target=$target"
