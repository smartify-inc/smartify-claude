---
description: Show your Smartify memory overview — drawer counts, wings, and rooms.
allowed-tools: mcp__smartify__hivemind_status
---

Call the `hivemind_status` tool on the `smartify` MCP server and present a concise summary of the user's Smartify memory: total drawers, the wings, and the rooms.

If the tool call fails, diagnose from the error and tell the user how to fix it:

- 401 / unauthorized: the API key is missing or invalid — re-check the plugin's `api_key`.
- 403: the key is valid but not scoped to this `hivemind_id` — use a key that owns this Hivemind.
- 404: the `api_base` is wrong or the gateway is disabled for this environment.
- "not connected": the `smartify` MCP server has not connected yet — ask the user to run `/reload-plugins` or restart Claude Code.

Never print the API key.
