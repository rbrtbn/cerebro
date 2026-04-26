# Ubiquitous Language

The canonical vocabulary for Cerebro. **Bold** terms are the names to use in
code, commits, PRs, issues, and conversation. The "Aliases to avoid" column
lists wording that would muddle the model.

If you find yourself reaching for an aliased word, that's the signal to use
the bold one — or to surface a missing term and add it here.

This document is the more recent source than `CLAUDE.md`'s glossary section.
When the two diverge, update CLAUDE.md to match this file.

## The system

| Term         | Definition                                                                            | Aliases to avoid     |
| ------------ | ------------------------------------------------------------------------------------- | -------------------- |
| **Cerebro**  | The personal aggregator and assistant. The whole system.                              | "the app", "the dashboard" |
| **Milestone**| A defined vertical slice of Cerebro's roadmap, gated by Rob's review.                 | "phase", "release", "sprint" |

## Data flow primitives

These are the moving parts of the materialized aggregator.

| Term         | Definition                                                                            | Aliases to avoid                  |
| ------------ | ------------------------------------------------------------------------------------- | --------------------------------- |
| **Source**   | An external system Cerebro pulls from (Gmail, Notion, GitHub, eversports-mcp, …).     | "data source", "integration", "provider" |
| **Worker**   | The deterministic-code component that pulls from one Source and writes to the Store. One Worker per Source. No LLM calls. | "sync agent", "ETL job", "ingester", "connector" |
| **Sync Run** | One execution of a Worker against a Source. Has a status, started-at, ended-at, error.| "fetch", "poll cycle", "run", "job" |
| **Store**    | The SQLite database Cerebro owns. Single source of truth for the Interfaces.          | "DB", "database", "cache", "warehouse" |

## AI roles

Cerebro carefully distinguishes three AI roles. They are NOT
interchangeable — each has a different lifecycle, trigger, and access pattern.
The bare word "agent" is **forbidden**; always name which one.

| Term       | Definition                                                                                          | Aliases to avoid                          |
| ---------- | --------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| **Curator**| The scheduled agent that reads the Store and produces Digests on a cadence. Writes back to the Store. | "summary agent", "background AI"          |
| **Digest** | The Curator's structured output for a time period. Stored, versioned, rendered by Interfaces.       | "brief", "briefing", "summary", "report"  |
| **Concierge** | The on-demand conversational agent. Has tool access to the Store (typed queries) and to MCP servers (for actions and uncached reads). | "chat", "assistant", "the agent", "AI" |
| **Concierge Session** | One conversation with the Concierge. Has a start, an end, and a transcript.             | "chat session", "thread", "conversation"  |

## External agents Cerebro observes (not owns)

| Term          | Definition                                                                              | Aliases to avoid                  |
| ------------- | --------------------------------------------------------------------------------------- | --------------------------------- |
| **Satellite** | An external coding agent (OpenClaw session, Claude Code background run, …) that Cerebro observes as a Source. Distinguishes external agents from Cerebro's own (Curator, Concierge). | "outpost", "external agent", "remote agent", "background run" |

## Interfaces

| Term                  | Definition                                                                                                                              | Aliases to avoid                  |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------- |
| **Interface**         | A way Rob interacts with Cerebro. Reads the Store directly. Writes happen via Sources or Satellites — never via direct DB writes from an Interface. | "frontend", "UI", "app", "client", "surface" |
| **Web Interface**     | The primary dashboard. `apps/web`. TanStack Start + shadcn/ui. Milestone 1.                                                             | "the web app", "the dashboard"    |
| **Desktop Interface** | Experimental OS-like UI with floating windows. `apps/desktop`. base-ui + react-rnd. Post-Milestone 1.                                   | "the desktop app", "the native app" |

## Transport

A *transport* is a protocol a Worker (or the Concierge) uses to reach a
Source or Satellite. Transports are pluggable per Source — they are not
domain primitives, just the wiring underneath.

| Term            | Definition                                                                       | Aliases to avoid                  |
| --------------- | -------------------------------------------------------------------------------- | --------------------------------- |
| **MCP Server**  | A Model Context Protocol server. The default transport for Sources we wire ourselves. Not synonymous with Source — a Source is the underlying system; MCP is one way to reach it. | "tool server" (when ambiguous)    |

Workers may also use **A2A** (Agent2Agent protocol) or vendor APIs (REST,
GraphQL, file-system tailing) when the Source or Satellite exposes one of
those instead. Transport choice is a per-Worker implementation detail, not
an architectural commitment.

## Milestone 1 instances

Concrete realizations of the above terms, used in the first vertical slice.

| Term                         | Definition                                                                       |
| ---------------------------- | -------------------------------------------------------------------------------- |
| **eversports** (Source)      | The eversports gym-booking platform. Cerebro's first Source.                     |
| **eversports-mcp**           | The MCP Server fronting eversports. Currently stale; Rob will revive it before integration. |
| **eversports Worker**        | The Worker that pulls from eversports-mcp and writes to the Store.               |
| **gym_bookings** (table)     | The Store table holding upcoming and historical bookings.                        |
| **sync_runs** (table)        | The Store table holding one row per Sync Run, across all Workers.                |

## Relationships

- A **Worker** belongs to exactly one **Source**. One Worker per Source — never many-to-one or many-to-many.
- A **Sync Run** belongs to exactly one **Worker** and represents one execution.
- The **Store** is written by **Workers** (and the **Curator**), and read by **Interfaces** and the **Concierge**.
- A **Digest** is produced by the **Curator**, persisted to the **Store**, and rendered by **Interfaces**.
- A **Concierge Session** reads from the **Store** and may invoke **MCP Servers** (or other transports) for live actions or uncached reads. It does not write to the Store.
- A **Satellite** is observed *via a Source* — Cerebro never controls it.
- An **Interface** never writes the Store directly. Interface-driven writes round-trip through a **Source** (the next **Sync Run** picks up the change) or a **Satellite**.
- A transport (**MCP Server**, **A2A**, vendor API) is wiring, not a Source. A Source may have zero, one, or many transports fronting it.

## Example dialogue

> **Rob:** "Why is yesterday's gym booking missing from the **Web Interface**?"
>
> **Claude:** "The **Web Interface** only reads from the **Store**, so the gap is upstream. The most recent **Sync Run** for the **eversports Worker** failed two hours ago — the **eversports-mcp** server returned a malformed response. No new rows landed in `gym_bookings`."
>
> **Rob:** "Could the **Concierge** have caught it earlier?"
>
> **Claude:** "Not on its own. The **Concierge** only runs when you open a **Concierge Session**. The **Curator** is the scheduled role — it would have flagged the stale **Sync Run** in the next **Digest**. We haven't built the **Curator** yet, though; that's post-Milestone 1."
>
> **Rob:** "And if I had a Claude Code agent fixing the eversports-mcp server in the background, would Cerebro know?"
>
> **Claude:** "Only if we model that agent as a **Satellite** — i.e., add a Source for it and a Worker that ingests its status. Satellites are external; Cerebro observes them but never controls them. The transport would depend on what the Satellite exposes — A2A if it speaks that, otherwise a vendor API or a file tail."

## Flagged ambiguities

- **"agent"** — used in this codebase for three distinct things: the **Curator** (scheduled), the **Concierge** (on-demand), and **Satellites** (external). The bare word "agent" is **forbidden**. Always name which one. **Workers are NOT agents** — they are deterministic code with no LLM calls; calling them agents conflates the AI roles with ETL.
- **"Source" vs "MCP Server"** — eversports is the **Source** (the underlying system); **eversports-mcp** is the MCP Server fronting it. A Source may exist without any MCP Server (e.g., a REST API a Worker hits directly). Don't use them interchangeably.
- **"Sync Run" vs "Worker"** — a **Worker** is a long-lived component (code that exists in the repo). A **Sync Run** is one *execution* of that Worker (a row in `sync_runs`). "The Worker failed" is ambiguous; prefer "the last **Sync Run** for the eversports **Worker** failed."
- **"Digest" vs "Concierge response"** — both are AI outputs, but a **Digest** is materialized to the Store and versioned, while a **Concierge** response is ephemeral within a **Concierge Session**. Don't conflate them.
- **"Interface" vs "app"** — `apps/web` and `apps/desktop` are the *directories*; **Web Interface** and **Desktop Interface** are the *concepts*. Use the concept names in domain conversation; reserve `apps/web` for filesystem references. The TypeScript keyword `interface` is unrelated and shares only the spelling.
- **"Interface" writes** — Interfaces *appear* to write (the user clicks "book a class") but never touch the Store directly. The action goes out via a **Source** or **Satellite**, and the next **Sync Run** brings the result back into the Store. If you find yourself calling Drizzle from an Interface route handler, you've broken the contract.
