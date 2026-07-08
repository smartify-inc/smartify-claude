---
description: Set up and verify the Smartify memory connection for Claude Code.
allowed-tools: mcp__smartify__hivemind_status, mcp__smartify__hivemind_search
---

Walk the user through verifying that Smartify memory is working in Claude Code, then confirm they are set up. Be concise.

1. Confirm the `smartify` MCP server is connected. If it is not, tell the user to enable the plugin and fill in its configuration (`hivemind_id`, `api_key`, and optionally `api_base`), then run `/reload-plugins` or restart Claude Code.
2. Call `hivemind_status` and report the total drawer count plus the wings and rooms. If it errors, diagnose:
   - 401 / unauthorized: bad or missing `api_key`.
   - 403: the key is not scoped to this `hivemind_id`.
   - 404: wrong `api_base`, or the gateway is disabled for this environment.
   Point the user to the plugin configuration or the Smartify dashboard to fix it.
3. Briefly explain the memory protocol so the user knows what to expect: before answering questions about past work, Claude calls `hivemind_search` (and `hivemind_kg_query` for people/dates/decisions); after answering, it files the exchange with `hivemind_smart_file_response` so it is remembered across sessions.
4. Optionally run one `hivemind_search` against a keyword the user provides to demonstrate retrieval.
5. Confirm the user is all set, or summarize the single thing they still need to fix.

Never print or echo the API key.
