# Smartify — Claude Code plugin

Gives Claude Code persistent, shared memory backed by your Smartify Hivemind. The plugin
bundles a remote MCP server (`smartify`), a memory-protocol skill, automatic-memory hooks,
and slash commands so Claude searches your memory before answering and files each exchange
afterward.

Requires Claude Code **v2.1.147 or newer** — older CLIs reject the plugin's `userConfig`
manifest (the plugin silently fails to load) or lack the `--config` flag for one-command
setup.

## Install

One command installs *and* configures the plugin. It checks your Claude Code version first
and refuses loudly if you are behind (on old CLIs the manifest is rejected and
`claude plugin install` still reports success):

```bash
need=2.1.147
have=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [ -z "$have" ]; then
  echo "Claude Code not found — install it from https://code.claude.com, then re-run."
elif [ "$(printf '%s\n%s\n' "$need" "$have" | sort -V | head -1)" != "$need" ]; then
  echo "Smartify needs Claude Code >= $need (you have $have). Update with: claude update"
else
  claude plugin marketplace add smartify-inc/smartify-claude
  claude plugin install smartify@smartify \
    --config hivemind_id=hm_xxxxxxxxxxxxxxxx \
    --config api_key=sk_live_xxxxxxxxxxxxxxxx
fi
```

Prefer to keep the key out of your shell history? Drop the `--config` lines and configure
inside Claude Code instead: `/plugin` → **Smartify** → **Configure**. Either way, these are
the values:

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
