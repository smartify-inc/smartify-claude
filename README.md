# smartify-claude

The Smartify plugin for [Claude Code](https://code.claude.com). It connects Claude Code to
your Smartify Hivemind over MCP, so Claude has persistent, shared memory: it searches your
memory before answering and files each exchange afterward.

This is the Claude Code equivalent of the Smartify memory integration that Cursor gets
through MCP plus a memory rule. It is memory-only — it does not route your model calls.

## Prerequisites

- [Claude Code](https://code.claude.com) installed.
- A Smartify account with at least one Hivemind. Note its id (`hm_…`).
- A Smartify SDK key scoped to that Hivemind (`sk_live_…` or `sk_test_…`), minted in the
  dashboard under Settings → API keys.

## Install

```bash
claude plugin marketplace add smartify-inc/smartify-claude
claude plugin install --scope user smartify
```

When you enable the plugin, Claude Code prompts for three values:

| Setting | Required | Description |
| --- | --- | --- |
| `hivemind_id` | yes | Your Hivemind id (`hm_…`). |
| `api_key` | yes | Smartify SDK key scoped to that Hivemind. Stored in your OS keychain (marked sensitive). |
| `api_base` | no | Gateway base URL including `/v1`. Defaults to `https://api.hivemind.smartify.ai/v1`. |

These feed the bundled MCP server config via `${user_config.*}` substitution; no secrets
are stored in the repository or in `settings.json`.

## Local development

Test changes without publishing by pointing Claude Code at the plugin directory:

```bash
claude --plugin-dir /path/to/smartify-claude/.claude-plugin
```

## What it contains

```
.claude-plugin/
├── plugin.json        # manifest + userConfig (hivemind_id, api_key, api_base)
├── marketplace.json   # smartify-inc/smartify-claude catalog entry
├── .mcp.json          # remote HTTP MCP server "smartify" → /v1/mcp/{hivemind_id}
├── README.md          # plugin-focused install notes
└── skills/
    └── smartify/
        └── SKILL.md   # memory protocol: search before answering, file after
```

The MCP server is named `smartify`; its tools keep their `hivemind_*` names (the Smartify
gateway API surface), so Claude calls `hivemind_status`, `hivemind_search`,
`hivemind_smart_file_response`, and so on.

## Verifying your setup

After enabling the plugin and running `/reload-plugins`:

1. Confirm the `smartify` MCP server appears in the plugin inventory:
   `claude plugin details smartify` (or the `/plugin` detail view).
2. Ask Claude to check memory — it should call `hivemind_status` and report a drawer count.
3. Ask about prior work — it should call `hivemind_search` before answering.
4. Finish a turn — it should call `hivemind_smart_file_response` to file the exchange.

You can sanity-check credentials independently of Claude Code with the smoke script:

```bash
HIVEMIND_ID=hm_xxx API_KEY=sk_live_xxx ./scripts/smoke-mcp.sh
```

A wrong Hivemind id for a given key returns `403 hivemind_access_denied`, confirming
tenant scoping.

## Scope

Phase 1 is memory-only. Auto-save hooks, slash commands (`/smartify:init`,
`/smartify:status`), a Connect-page install tile, and gateway model routing are planned for
later phases.
