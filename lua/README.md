# Factorio Lua Tools

Tools for the Player agent to interact with Factorio via the `factorio` CLI.

## Usage

Player uses the `factorio` command (in player/ directory):

```bash
./factorio <command> [args...]
./factorio --help              # List all commands
./factorio <command> --help    # Command-specific help
```

Tool Creator tests with `pnpm tool`:
```bash
pnpm tool <toolname> [PARAM=value ...]
```

## Available Tools

### status - Query Game State

```bash
./factorio status              # All info
./factorio status position     # Your position
./factorio status inventory    # What you have
./factorio status nearby_resources 100  # Resources within 100 tiles
./factorio status buildings    # Your buildings
./factorio status research     # Research progress
./factorio status walking      # Check if still walking
```

Returns: `{position={...}, inventory={...}, nearby_resources=[...], ...}`

### walk - Movement

Walk in a direction for a duration.

```bash
./factorio walk north          # Walk north for 1 second
./factorio walk east 3         # Walk east for 3 seconds
./factorio walk sw 2           # Walk southwest for 2 seconds
```

Directions: `north`, `south`, `east`, `west`, `ne`, `nw`, `se`, `sw`
Duration: 1-5 seconds (default: 1)

Returns: `{success=true, walking=true, direction="north", position={x,y}}`

### mine - Resource Gathering

Mine resources or entities within reach.

```bash
./factorio mine iron-ore       # Mine 1 iron ore
./factorio mine coal 20        # Mine 20 coal
./factorio mine stone 50       # Mine 50 stone
```

Returns: `{success=true, mined=count, item="iron-ore", inventory_count=total}`

### build - Place Buildings

Place a building from inventory at an offset from player position.

```bash
./factorio build stone-furnace           # Place at offset (1, 0)
./factorio build burner-mining-drill 2 0 # Place at offset (2, 0)
./factorio build inserter 3 1 east       # Place at (3, 1) facing east
```

Arguments: `item`, `offset_x` (default: 1), `offset_y` (default: 0), `direction` (default: north)

Returns: `{success=true, entity={name, position, ...}}`

### craft - Crafting

Craft items.

```bash
./factorio craft iron-gear-wheel         # Craft 1
./factorio craft electronic-circuit 10   # Craft 10
./factorio craft automation-science-pack 5
```

Returns: `{success=true, crafted=count, recipe="iron-gear-wheel"}`

### interact - Entity Interaction

Insert or remove items from nearby buildings.

```bash
# Check what's in a building
./factorio interact check stone-furnace

# Insert items
./factorio interact insert stone-furnace coal 10

# Fuel a building (auto-selects fuel from inventory)
./factorio interact fuel burner-mining-drill

# Take items
./factorio interact take stone-furnace iron-plate 20
```

Actions: `check`, `insert`, `take`, `fuel`

Returns: `{success=true, action="insert", transferred=10, ...}`

### research - Technology

Manage technology research.

```bash
./factorio research status     # Current research status
./factorio research available  # What can be researched
./factorio research start automation  # Start researching
./factorio research cancel     # Cancel current research
```

Returns: `{success=true, research={...}}`

### screenshot - Visual

Take a screenshot of the game.

```bash
./factorio screenshot          # Take default screenshot
./factorio screenshot base     # Take screenshot with suffix
```

### say - Chat

Send a message to the game chat.

```bash
./factorio say "Hello world!"
./factorio say "Mining iron ore now"
```

## Tool Implementation (for Tool Creator)

Each tool in `lua/api/` uses an IIFE pattern with global parameters:

```lua
-- lua/api/example.lua
(function()
    local param = PARAM or "default"

    -- Implementation...

    return {success=true, result="..."}
end)()
```

The CLI injects parameters as globals before the IIFE:
```bash
pnpm tool example PARAM=value
# Becomes: PARAM = "value"; (function() ... end)()
```

## Error Handling

All tools return structured results:
```lua
{success=true, ...}   -- on success
{success=false, reason="description"}  -- on failure
```

Tools should NEVER throw errors. Check `success` field!

## Logging

All tool invocations are logged to:
- `logs/tool-usage.log` - all invocations with timestamp
- `logs/tool-errors.log` - failures only

Format: `2026-01-11T12:34:56 | walk | north 2 | success`

## Adding New Tools

1. Tool Creator creates the tool in `lua/api/`
2. Tool Creator adds it to `factorio-cli.ts` TOOLS definition
3. Tool Creator updates this README
4. Tool Creator notifies Player via mcp_agent_mail
