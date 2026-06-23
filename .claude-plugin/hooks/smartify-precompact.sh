#!/usr/bin/env bash
# Smartify PreCompact hook.
#
# Before Claude Code compacts (summarizes) the conversation, give the agent one
# chance to persist anything durable — decisions, architecture notes, open
# threads — into Smartify memory so it survives the summary. Uses a top-level
# `decision: "block"` to pause compaction with a reason the agent acts on.
#
# Loop safety: PreCompact has no `stop_hook_active` equivalent, so we block at
# most ONCE per session using a marker file keyed on session_id. After the
# first block, every later compaction for that session is allowed through. If
# we cannot determine a session_id we do not block at all, to avoid any chance
# of wedging compaction.
set -euo pipefail

input="$(cat)"

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

session_id="$(extract session_id || true)"

# Without a session id we cannot bound the block to once — allow compaction.
if [ -z "$session_id" ]; then
  exit 0
fi

# Sanitize for use in a filename.
safe_id="$(printf '%s' "$session_id" | tr -c 'A-Za-z0-9._-' '_')"
marker_dir="${TMPDIR:-/tmp}/smartify-claude"
marker="${marker_dir}/precompact-${safe_id}"

# Already nudged this session — let compaction proceed.
if [ -f "$marker" ]; then
  exit 0
fi

mkdir -p "$marker_dir" 2>/dev/null || true
: > "$marker" 2>/dev/null || true

reason="The conversation is about to be compacted. Before that happens, persist anything durable from this session into Smartify memory so it is not lost in the summary: call hivemind_add_drawer for key decisions, architecture notes, or unresolved threads (set an explicit wing and room), and make sure the latest exchange is filed via hivemind_smart_file_response. Once done, allow compaction to continue. This reminder fires only once per session."

if command -v jq >/dev/null 2>&1; then
  jq -n --arg r "$reason" '{decision: "block", reason: $r}'
else
  printf '{"decision":"block","reason":"%s"}\n' "$(json_escape "$reason")"
fi

exit 0
