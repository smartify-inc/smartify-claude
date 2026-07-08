# smartify-claude

The Smartify plugin for [Claude Code](https://code.claude.com). It connects Claude Code to
your Smartify Hivemind over MCP, so Claude has persistent, shared memory: it searches your
memory before answering and files each exchange afterward.

This is the Claude Code equivalent of the Smartify memory integration that Cursor gets
through MCP plus a memory rule. It is memory-only — it does not route your model calls.

## Prerequisites

- [Claude Code](https://code.claude.com) **v2.1.143 or newer**. The plugin uses `userConfig`
  for guided, keychain-backed setup, which older CLIs reject as an invalid manifest (the
  plugin silently fails to load). Run `claude --version`; update with `claude update` (or
  reinstall) if you are behind.
- A Smartify account with at least one Hivemind. Note its id (`hm_…`).
- A Smartify SDK key scoped to that Hivemind (`sk_live_…` or `sk_test_…`), minted in the
  dashboard under Settings → API keys.

## Install

The plugin fails to load on Claude Code older than v2.1.143, and Claude Code reports that
only in its debug log — `claude plugin install` still says "success". So the snippet below
checks your version first and refuses loudly instead of installing something that won't work:

```bash
need=2.1.143
have=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [ -z "$have" ]; then
  echo "Claude Code not found — install it from https://code.claude.com, then re-run."
elif [ "$(printf '%s\n%s\n' "$need" "$have" | sort -V | head -1)" != "$need" ]; then
  echo "Smartify needs Claude Code >= $need (you have $have). Update with: claude update"
else
  claude plugin marketplace add smartify-inc/smartify-claude
  claude plugin install smartify@smartify
fi
```

Then open Claude Code and configure it through the interactive menu — run `/plugin`, select
**Smartify**, and choose **Configure**. (A non-interactive `claude plugin install` enables the
plugin but does not open the config dialog, so configure it here.) You will be prompted for
three values:

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
claude --plugin-dir /path/to/smartify-claude
```

## What it contains

Claude Code requires `plugin.json` inside `.claude-plugin/` and every other component
(`.mcp.json`, `skills/`, `commands/`, `hooks/`) at the plugin root — not nested inside
`.claude-plugin/`. The marketplace entry's `source` is `"./"` (the repo root is the plugin).

```
smartify-claude/                # plugin root
├── .claude-plugin/
│   ├── plugin.json             # manifest + userConfig (hivemind_id, api_key, api_base)
│   ├── marketplace.json        # smartify-inc/smartify-claude catalog entry (source: "./")
│   └── README.md               # plugin-focused install notes
├── .mcp.json                   # remote HTTP MCP server "smartify" → /v1/mcp/{hivemind_id}
├── skills/
│   └── smartify/
│       └── SKILL.md            # memory protocol: search before answering, file after
├── commands/
│   ├── init.md                 # /smartify:init — verify + onboard
│   └── status.md               # /smartify:status — memory overview
└── hooks/
    ├── hooks.json              # registers SessionStart / Stop / PreCompact
    ├── smartify-session-start.sh
    ├── smartify-stop.sh
    └── smartify-precompact.sh
```

The MCP server is named `smartify`; its tools keep their `hivemind_*` names (the Smartify
gateway API surface), so Claude calls `hivemind_status`, `hivemind_search`,
`hivemind_smart_file_response`, and so on.

## Slash commands

| Command | What it does |
| --- | --- |
| `/smartify:init` | Verifies the connection, runs `hivemind_status`, explains the memory protocol, and reports anything left to fix. |
| `/smartify:status` | Shows your memory overview — drawer count, wings, and rooms. |

## Hooks (automatic memory)

The skill tells Claude what to do; the hooks make it reliable without you having to ask.

| Hook | Behavior |
| --- | --- |
| `SessionStart` | Injects a stable `session_id` and the memory protocol into context, so every exchange in the chat is filed under one session and search/file happen consistently. |
| `Stop` | A backstop that reminds Claude to file the exchange via `hivemind_smart_file_response` before the turn ends. Fires at most once per turn (guarded by `stop_hook_active`) and uses non-error "Stop hook feedback". |
| `PreCompact` | Before the conversation is compacted, prompts Claude once per session to persist durable context (decisions, architecture notes) via `hivemind_add_drawer` so it survives the summary. |

The hooks are dependency-free shell scripts. They use `jq` when present for robust JSON
parsing and fall back to `grep`/`sed` otherwise. No API key is ever read or printed by a
hook — they only inject reminders; the actual memory calls go through the `smartify` MCP
server using your configured credentials.

## Verifying your setup

After enabling the plugin and running `/reload-plugins`:

1. Run `/smartify:init` — it verifies the connection, runs `hivemind_status`, and reports
   anything left to fix.
2. Confirm the `smartify` MCP server appears in the plugin inventory:
   `claude plugin details smartify` (or the `/plugin` detail view).
3. Ask about prior work — it should call `hivemind_search` before answering.
4. Finish a turn — it should call `hivemind_smart_file_response` to file the exchange (the
   `Stop` hook reminds it if needed).

You can sanity-check credentials independently of Claude Code with the smoke script:

```bash
HIVEMIND_ID=hm_xxx API_KEY=sk_live_xxx ./scripts/smoke-mcp.sh
```

A wrong Hivemind id for a given key returns `403 hivemind_access_denied`, confirming
tenant scoping.

## Scope

The plugin covers memory: a remote MCP server, a memory-protocol skill, automatic-memory
hooks (`SessionStart` / `Stop` / `PreCompact`), and the `/smartify:init` and
`/smartify:status` slash commands. A Connect-page install tile and gateway model routing
(Anthropic `/v1/messages`) are planned for later.
