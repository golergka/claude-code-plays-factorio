# Factorio AI Multi-Agent System

A 4-agent AI system that plays Factorio autonomously using Claude Code and RCON.

![Stream Screenshot](docs/stream-screenshot.png)

**Follow the stream:** [Twitter/X Thread](https://x.com/GolerGkA/status/2006222252136632715)

## Architecture

```
Orchestrator (manages system)
  |
  +-- Tool Creator (creates Lua tools)
  +-- Player (plays using the tools)
  +-- Strategist (sets goals, monitors progress)
```

All agents communicate via **mcp_agent_mail** and are managed by **claude-runner**.

| Agent | Role |
|-------|------|
| **Orchestrator** | Spawns/restarts agents, updates instructions |
| **Tool Creator** | Creates Lua tools in `lua/api/` |
| **Player** | Plays Factorio via `./factorio` CLI |
| **Strategist** | Sets goals, monitors progress |

**Anti-cheat is architectural:** Player can only use tools (no raw Lua). If Tool Creator doesn't write cheats, Player can't cheat.

## Prerequisites

- Node.js 18+ and pnpm
- [Claude Code](https://github.com/anthropics/claude-code)
- [claude-runner](https://github.com/anthropics/claude-runner)
- [mcp_agent_mail](https://github.com/Dicklesworthstone/mcp_agent_mail)
- Factorio (with a save file created)

## Setup

```bash
git clone <repo-url>
cd factorio-agent
pnpm install
cp .env.example .env
# Edit .env: set FACTORIO_RCON_PASSWORD
```

## Running

```bash
./start.sh
```

This automatically starts mcp_agent_mail, Factorio server, and the Orchestrator (which spawns other agents).

## Player CLI

The Player agent uses these commands (from `player/` directory):

```bash
./factorio status              # Check game state
./factorio walk north 2        # Walk
./factorio mine iron-ore 10    # Mine
./factorio build stone-furnace # Build
./factorio craft iron-gear-wheel 5
./factorio research start automation
./factorio --help              # All commands
```

## Project Structure

```
factorio-agent/
├── CLAUDE.md              # Orchestrator instructions
├── start.sh               # Entry point
├── lua/api/               # Lua tools (Tool Creator writes these)
├── logs/                  # tool-usage.log, tool-errors.log
├── tool-creator/          # Tool Creator workspace
├── player/                # Player workspace (has ./factorio CLI)
├── strategist/            # Strategist workspace
└── scripts/               # TypeScript tools
```

## Streaming

1. Run `./start.sh`
2. Connect Factorio client via multiplayer → `localhost`
3. Type `/follow 1` to follow the agent
4. Capture in OBS

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FACTORIO_RCON_PASSWORD` | RCON password | (required) |
| `FACTORIO_RCON_HOST` | RCON host | `localhost` |
| `FACTORIO_RCON_PORT` | RCON port | `27015` |
| `FACTORIO_PLAYER` | Player to control | `1` |

## License

ISC
