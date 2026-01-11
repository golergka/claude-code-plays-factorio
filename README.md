# Factorio AI Multi-Agent System

A 4-agent AI system that plays Factorio autonomously using Claude Code and RCON.

![Stream Screenshot](docs/stream-screenshot.png)

*Claude Code agents autonomously playing Factorio via RCON*

**Follow the stream:** [Twitter/X Thread](https://x.com/GolerGkA/status/2006222252136632715)

## Architecture

This project uses a **4-agent architecture** where each agent has a distinct role:

```
Orchestrator (manages system)
  |
  +-- Tool Creator (creates Lua tools for gameplay)
  +-- Player (plays using the tools)
  +-- Strategist (sets goals, monitors progress)
```

All agents communicate via **mcp_agent_mail** and are managed by **claude-runner**.

### Agent Roles

| Agent | Role | Access |
|-------|------|--------|
| **Orchestrator** | Meta-manager, spawns/restarts agents, updates instructions | Everything |
| **Tool Creator** | Creates Lua tools in `lua/api/`, enforces realistic gameplay | Lua files, pnpm commands |
| **Player** | Plays Factorio using CLI tools | `./factorio` CLI only |
| **Strategist** | Sets goals for Player, monitors progress | Logs (read), mail |

### Anti-Cheat by Design

Anti-cheat is **architectural**, not runtime:
- Player can ONLY use the `factorio` CLI (no raw Lua)
- The CLI only executes tools from `lua/api/`
- Tool Creator writes the tools - if they don't write cheats, Player can't cheat

## Prerequisites

- **Node.js** 18+ and **pnpm**
- **Claude Code** installed (`npm install -g @anthropic-ai/claude-code`)
- **claude-runner** (for managing agent processes)
- **mcp_agent_mail** (for agent communication)
- **Factorio** (Steam or standalone version)

## Setup

### 1. Clone and Install

```bash
git clone <repo-url>
cd factorio-agent
pnpm install
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your RCON password and player target
```

### 3. Install mcp_agent_mail

```bash
# Clone and set up mcp_agent_mail
git clone https://github.com/Dicklesworthstone/mcp_agent_mail
cd mcp_agent_mail
python -m venv .venv
source .venv/bin/activate
pip install -e .
```

### 4. Start Factorio Server

Factorio must run as a **dedicated server** (RCON doesn't work in single-player).

```bash
# Create a save file first (via game UI), then:
pnpm server:start
```

Or manually:
```bash
factorio --start-server /path/to/saves/your-save.zip \
         --rcon-port 27015 \
         --rcon-password your_password_here
```

### 5. Test Connection

```bash
pnpm eval "player.position"
# Should output something like: {x = 0, y = 0}
```

## Running the System

### Start Everything

```bash
./start.sh
```

This will:
1. Start mcp_agent_mail server (if not running)
2. Start Factorio server (if not running)
3. Launch the Orchestrator via claude-runner
4. Orchestrator spawns the other 3 agents

### Manual Agent Startup

If you prefer to start agents manually:

```bash
# Start mcp_agent_mail
cd /path/to/mcp_agent_mail && source .venv/bin/activate
python -m mcp_agent_mail.cli serve-http --port 8765 &

# Start Factorio server
pnpm server:start &

# Start Orchestrator (which spawns other agents)
claude-runner --task-file CLAUDE.md --working-dir . --session-id factorio-orchestrator
```

## Player CLI

The Player agent uses a simple CLI interface:

```bash
# From player/ directory
./factorio status              # Check game state
./factorio walk north 2        # Walk north for 2 seconds
./factorio mine iron-ore 10    # Mine 10 iron ore
./factorio build stone-furnace # Place a furnace
./factorio craft iron-gear-wheel 5
./factorio interact insert stone-furnace coal 10
./factorio research start automation
./factorio screenshot
./factorio --help              # List all commands
```

## Project Structure

```
factorio-agent/
├── CLAUDE.md              # Orchestrator instructions
├── start.sh               # Entry point (starts everything)
├── package.json
│
├── lua/                   # Shared: Tool Creator writes, Player uses
│   ├── api/               # Lua tools (status, walk, mine, build, etc.)
│   └── README.md          # Tool documentation
│
├── logs/                  # Shared logs
│   ├── tool-usage.log     # All tool invocations
│   └── tool-errors.log    # Errors
│
├── tool-creator/          # Tool Creator workspace
│   └── CLAUDE.md
├── player/                # Player workspace
│   ├── CLAUDE.md
│   └── factorio           # CLI wrapper script
├── strategist/            # Strategist workspace
│   └── CLAUDE.md
│
└── scripts/               # TypeScript tools
    ├── factorio-cli.ts    # Player CLI
    ├── factorio-eval.ts   # Raw Lua execution
    └── factorio-tool.ts   # Tool execution
```

## Streaming Setup

Perfect for running an autonomous AI stream!

### Setup

1. **Start the system** with `./start.sh`
2. **Launch Factorio client** and connect via multiplayer (Direct Connect → `localhost`)
3. **Follow the agent's character**: Type `/follow 1` in game chat
4. **Start OBS** and capture the Factorio window

### What Viewers Will See

- The game camera following the AI-controlled character
- Agent communication via mcp_agent_mail
- Every command logged to `logs/tool-usage.log`
- The agent mining, building, crafting, and expanding the factory

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FACTORIO_RCON_HOST` | RCON server hostname | `localhost` |
| `FACTORIO_RCON_PORT` | RCON server port | `27015` |
| `FACTORIO_RCON_PASSWORD` | RCON password | (required) |
| `FACTORIO_PLAYER` | Player index or name to control | `1` |
| `FACTORIO_SHOW_COMMANDS` | Show AI commands in game chat | `false` |

## Factorio Lua API Reference

The tools use Factorio's Lua API via RCON. Key classes:

- [LuaGameScript](https://lua-api.factorio.com/latest/classes/LuaGameScript.html) - `game.*`
- [LuaPlayer](https://lua-api.factorio.com/latest/classes/LuaPlayer.html) - `player.*`
- [LuaSurface](https://lua-api.factorio.com/latest/classes/LuaSurface.html) - `surface.*`
- [LuaControl](https://lua-api.factorio.com/latest/classes/LuaControl.html) - Player actions

## Limitations

- **Single-player not supported**: RCON only works with dedicated servers
- **Achievements disabled**: Using Lua commands disables Steam achievements

## License

ISC
