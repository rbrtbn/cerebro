# Cerebro

Personal aggregator and assistant. The single place to see the state of my
digital life — emails, articles, side-project status, calendar, gym bookings,
running coding agents — with a chat surface for synthesis and ad-hoc questions.

Read-mostly dashboard first. Chat layer second.

## Architecture (at a glance)

**Materialized aggregator.** Cerebro owns its own SQLite database. Per-Source
**Workers** (deterministic ETL, no LLMs) pull data on schedules or via webhooks
and write to the local **Store**. **Surfaces** (`apps/web`, later `apps/desktop`)
only ever read from the Store.

Two AI roles, both deferred past Milestone 1:

- **Curator** — scheduled agent producing Briefs from the Store.
- **Concierge** — on-demand chat with tool access to the Store and MCP servers.

**Outposts** (external coding agents like OpenClaw sessions) are a future
Source — Cerebro observes, doesn't own.

See [`CONTEXT.md`](./CONTEXT.md) for the canonical glossary and
[`CLAUDE.md`](./CLAUDE.md) for working conventions.

## Status

Pre-Milestone 1. Repo skeleton only. The first vertical slice is the
eversports gym-booking pipeline:

`eversports-mcp Source → eversports Worker → Store → Web Surface route`

## Setup

_To be filled in as the project develops._

```bash
# pnpm i
# op run -- pnpm vp dev
```
