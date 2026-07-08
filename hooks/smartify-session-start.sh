#!/usr/bin/env bash
# Smartify SessionStart hook.
#
# Injects a stable session_id plus the Smartify memory protocol into Claude's
# context at the start of every session, so the agent files every exchange in
# this chat under one session_id and searches memory before answering.
#
# This hook only injects context — MCP servers are typically not connected yet
# when SessionStart fires, so it does not call any tool. It has no local
# dependencies beyond the standard shell; jq is used when available for robust
# JSON parsing, with a grep/sed fallback so the hook still works without it.
set -euo pipefail

input="$(cat)"

extract() {
  # extract <key> — pull a top-level string value from the hook input JSON.
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

session_id="$(extract session_id || true)"
[ -z "$session_id" ] && session_id="claude-$(date +%s)"

read -r -d '' context <<EOF || true
Smartify memory is connected via the \`smartify\` MCP server. Use it as shared, persistent memory for this session.

Session id for this chat: ${session_id}
Use this exact value as \`session_id\` for every \`hivemind_smart_file_response\` call so all turns group together.

On your first turn, call \`hivemind_status\` to load the live memory protocol. Before answering anything about past work, people, decisions, or projects, call \`hivemind_search\` (short keywords only) and, for people/dates/relationships, \`hivemind_kg_query\`. After answering, file the exchange with \`hivemind_smart_file_response({ question, answer, session_id, wing })\`, using the workspace folder name as \`wing\`.
EOF

if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "$context" \
    '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
else
  # stdout is added to context for SessionStart even without JSON, so print the
  # reminder directly when jq is unavailable.
  printf '%s\n' "$context"
fi

exit 0
