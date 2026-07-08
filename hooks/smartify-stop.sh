#!/usr/bin/env bash
# Smartify Stop hook.
#
# A backstop that reminds Claude to file the just-completed exchange into
# Smartify memory before the turn ends. Uses the gentle
# `hookSpecificOutput.additionalContext` form (labeled "Stop hook feedback",
# not a hook error) so the conversation continues and Claude can file, then
# stop.
#
# Loop safety: when `stop_hook_active` is true the turn is already continuing
# because of a prior Stop-hook nudge, so we stay silent and allow the stop.
# This caps the nudge at once per turn (Claude Code also hard-caps at 8
# consecutive continuations).
set -euo pipefail

input="$(cat)"

json_bool() {
  # json_bool <key> — echo "true" if the top-level key is boolean true.
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r --arg k "$key" 'if (.[$k] // false) == true then "true" else "false" end'
  else
    if printf '%s' "$input" | grep -Eq "\"$key\"[[:space:]]*:[[:space:]]*true"; then
      echo "true"
    else
      echo "false"
    fi
  fi
}

extract() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r --arg k "$key" '.[$k] // empty'
  else
    printf '%s' "$input" \
      | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
      | head -n1 \
      | sed -E "s/.*:[[:space:]]*\"([^\"]*)\"/\1/"
  fi
}

json_escape() {
  # Escape a single-line string for embedding inside a JSON string literal.
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Already continuing because of us — let the turn end.
if [ "$(json_bool stop_hook_active)" = "true" ]; then
  exit 0
fi

session_id="$(extract session_id || true)"
session_line=""
[ -n "$session_id" ] && session_line=" Use session_id \"${session_id}\"."

reason="Before finishing: if you have not already filed this exchange into Smartify memory this turn, call hivemind_smart_file_response({ question, answer, session_id, wing }) now.${session_line} Use the workspace folder name as wing. If you already filed it, you may stop."

if command -v jq >/dev/null 2>&1; then
  jq -n --arg r "$reason" \
    '{hookSpecificOutput: {hookEventName: "Stop", additionalContext: $r}}'
else
  # Hand-built JSON fallback; escape quotes/backslashes so output stays valid.
  printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"%s"}}\n' "$(json_escape "$reason")"
fi

exit 0
