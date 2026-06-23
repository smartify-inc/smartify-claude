#!/usr/bin/env bash
# Smoke-test the Smartify MCP endpoint independently of Claude Code.
#
# Posts a JSON-RPC `tools/list` to /v1/mcp/{hivemind_id} with a bearer key
# and checks that the Smartify tool catalog comes back. This is the same
# wire shape the plugin's `smartify` MCP server uses, so a green run here
# means your hivemind_id + api_key + api_base are valid.
#
# Usage:
#   HIVEMIND_ID=hm_xxx API_KEY=sk_live_xxx ./scripts/smoke-mcp.sh
#   API_BASE=https://api.staging.hivemind.smartify.ai/v1 \
#     HIVEMIND_ID=hm_xxx API_KEY=sk_test_xxx ./scripts/smoke-mcp.sh
set -euo pipefail

API_BASE="${API_BASE:-https://api.hivemind.smartify.ai/v1}"
HIVEMIND_ID="${HIVEMIND_ID:?set HIVEMIND_ID (hm_…)}"
API_KEY="${API_KEY:?set API_KEY (sk_live_… or sk_test_…)}"

# Normalize trailing slashes so we never build …/v1//mcp/<id>.
base="${API_BASE%/}"
url="${base}/mcp/${HIVEMIND_ID}"

echo "POST ${url}"

# Streamable HTTP may answer as a single JSON object or an SSE stream,
# so we accept both and capture the HTTP status separately from the body.
tmp_body="$(mktemp)"
trap 'rm -f "$tmp_body"' EXIT

status="$(
  curl -sS -o "$tmp_body" -w '%{http_code}' \
    -X POST "$url" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    -H "Authorization: Bearer ${API_KEY}" \
    --data '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
)"

echo "HTTP ${status}"

if [[ "$status" == "404" ]]; then
  echo "MCP gateway disabled (404) for this environment or unknown hive." >&2
  exit 1
fi
if [[ "$status" == "401" ]]; then
  echo "Unauthorized (401) — check your API key." >&2
  exit 1
fi
if [[ "$status" == "403" ]]; then
  echo "Forbidden (403) — the key is valid but not scoped to ${HIVEMIND_ID}." >&2
  exit 1
fi
if [[ "${status:0:1}" != "2" ]]; then
  echo "Unexpected status ${status}. Body:" >&2
  cat "$tmp_body" >&2
  exit 1
fi

# Peel an SSE `data:` line if the body is not pure JSON.
payload="$(cat "$tmp_body")"
if ! echo "$payload" | jq empty >/dev/null 2>&1; then
  payload="$(printf '%s\n' "$payload" | awk '/^data:/{sub(/^data:[[:space:]]*/, ""); print; exit}')"
fi

tool_count="$(echo "$payload" | jq -r '.result.tools | length' 2>/dev/null || echo 0)"
echo "Tools returned: ${tool_count}"

if echo "$payload" | jq -e '.result.tools[]?.name | select(. == "hivemind_status")' >/dev/null 2>&1; then
  echo "OK — Smartify MCP reachable and hivemind_status is available."
  exit 0
fi

echo "Reached the endpoint but did not find hivemind_status in the catalog. Raw body:" >&2
echo "$payload" >&2
exit 1
