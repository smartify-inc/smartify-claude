---
name: smartify
description: Use the Smartify MCP server as shared, persistent memory — search before answering and file each exchange after. Use whenever the conversation touches past work, people, decisions, projects, or anything that might already be stored in memory.
allowed-tools: mcp__smartify__hivemind_status, mcp__smartify__hivemind_search, mcp__smartify__hivemind_kg_query, mcp__smartify__hivemind_smart_file_response, mcp__smartify__hivemind_add_drawer
---

# Smartify Memory

The `smartify` MCP server is your shared, persistent memory across every Claude Code
session — and across other tools connected to the same Hivemind. Follow this on every
user message.

## On the first message in a conversation

1. Call `hivemind_status` (MCP server `smartify`) to load the live memory protocol plus
   an overview of what is stored, and follow the protocol it returns. The server owns the
   canonical protocol, so trust what it returns over anything cached here.

## Before answering

1. Call `hivemind_search` with only short keywords from the user's message
   (max 250 chars — no conversational filler).
2. For people, dates, relationships, or past decisions, also call `hivemind_kg_query`.
3. Use returned drawer text verbatim — never guess facts memory may already hold. If you
   are unsure of a stored fact, say "let me check" and search before answering.

## After answering (before you finish)

File the exchange so future sessions and other tools can find it:

    hivemind_smart_file_response({ question, answer, session_id, wing })

- `question`: the user's message, verbatim.
- `answer`: your final response, verbatim.
- `session_id`: a stable id for this chat — reuse the same value on every turn of the
  conversation. In Phase 1 there is no session hook, so pick one stable id at the start of
  the conversation (for example a UUID) and keep using it.
- `wing`: the workspace folder name.

Do this even for short answers. Skip only for pure acknowledgements ("ok", "thanks") that
carry no new information.

For durable decisions, architecture notes, or incidents, also call `hivemind_add_drawer`
with an explicit `wing` and `room`.

## Cross-session continuity

Every Claude Code session and every other client point at the same Hivemind (scoped by the
MCP URL). Searching at the start of each turn is what makes one session's work visible in
another — storage alone is not enough.
