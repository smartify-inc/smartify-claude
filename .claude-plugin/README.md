# Smartify — Claude Code plugin

Gives Claude Code persistent, shared memory backed by your Smartify Hivemind. The plugin
bundles a remote MCP server (`smartify`), a memory-protocol skill, automatic-memory hooks,
and slash commands so Claude searches your memory before answering and files each exchange
afterward.

## Install

```bash
claude plugin marketplace add smartify-inc/smartify-claude
claude plugin install --scope user smartify
```

When you enable the plugin, Claude Code prompts for:

| Setting | Description |
| --- | --- |
| Hivemind ID | Your `hm_…` id from the Smartify dashboard. |
| API key | A Smartify SDK key scoped to that Hivemind (`sk_live_…` / `sk_test_…`). Stored in your system keychain. |
| API base URL | Defaults to `https://api.hivemind.smartify.ai/v1`. Change only for staging or self-hosted. |

The API key is marked sensitive, so it is stored in your OS keychain — never written to
`settings.json` and never committed.

## After install

The `smartify` MCP server starts automatically when the plugin is enabled. If you change
the configuration, run `/reload-plugins` (or restart Claude Code) to pick up MCP changes.

Verify it is working by running `/smartify:init`, or ask Claude to check memory — it should
call `hivemind_status` and report your stored drawer count.

## Commands and hooks

- `/smartify:init` — verify the connection and onboard.
- `/smartify:status` — show your memory overview (drawers, wings, rooms).
- Hooks: `SessionStart` injects a stable session id + protocol, `Stop` reminds Claude to
  file each exchange, and `PreCompact` preserves durable context before compaction. They are
  dependency-free shell scripts and never read or print your API key.

See the [repository README](https://github.com/smartify-inc/smartify-claude) for full
setup and troubleshooting.
