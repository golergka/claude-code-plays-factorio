# Factorio Lua Tools

Tools for the Player agent to interact with Factorio.

## Usage

Use the `pnpm tool` command to run tools with parameters:

```bash
pnpm tool <toolname> [param1=value1] [param2=value2] ...
```

Or run without parameters using `pnpm eval:file`:

```bash
pnpm eval:file lua/api/status.lua
```

## Available Tools

### Movement

#### walk.lua
Walk in a direction for a duration.

```lua
dofile('lua/api/walk.lua')({
    direction = "north",  -- north|south|east|west|ne|nw|se|sw
    duration = 2          -- seconds (default: 1, max: 5)
})
-- Returns: {success=true, position={x,y}, walked_for=seconds}
--      or: {success=false, reason="hit water"}
```

### Resource Gathering

#### mine.lua
Mine resources or entities within reach.

```lua
dofile('lua/api/mine.lua')({
    target = "iron-ore",  -- resource name or entity name
    count = 10            -- how many to mine (default: 1)
})
-- Returns: {success=true, mined=count, inventory={item=count,...}}
--      or: {success=false, reason="no iron-ore in reach"}
```

### Building

#### build.lua
Place a building from inventory.

```lua
dofile('lua/api/build.lua')({
    item = "stone-furnace",     -- item name
    position = {x=10, y=20},    -- absolute position
    -- OR
    offset = {x=2, y=0}         -- relative to player
})
-- Returns: {success=true, entity=entity_info}
--      or: {success=false, reason="position blocked"}
```

### Crafting

#### craft.lua
Craft items.

```lua
dofile('lua/api/craft.lua')({
    recipe = "iron-gear-wheel",
    count = 5
})
-- Returns: {success=true, crafting=count, queue_position=1}
--      or: {success=false, reason="missing ingredients"}
```

### Entity Interaction

#### interact.lua
Insert or remove items from buildings.

```lua
-- Insert items
dofile('lua/api/interact.lua')({
    action = "insert",
    entity_name = "stone-furnace",  -- finds nearest
    items = {name="coal", count=5}
})

-- Remove items
dofile('lua/api/interact.lua')({
    action = "remove",
    entity_name = "stone-furnace",
    inventory = "result"  -- source|result|fuel
})
-- Returns: {success=true, transferred=count}
```

### Status Queries

#### status.lua
Query game state.

```lua
-- Position
dofile('lua/api/status.lua')({query="position"})
-- Returns: {x=10.5, y=20.3}

-- Inventory
dofile('lua/api/status.lua')({query="inventory"})
-- Returns: {iron-plate=50, coal=20, ...}

-- Nearby resources
dofile('lua/api/status.lua')({query="nearby_resources", radius=50})
-- Returns: [{name="iron-ore", position={x,y}, distance=15}, ...]

-- Buildings
dofile('lua/api/status.lua')({query="buildings", radius=50})
-- Returns: [{name="stone-furnace", position={x,y}, status="working"}, ...]

-- Research
dofile('lua/api/status.lua')({query="research"})
-- Returns: {current="automation", progress=0.45, completed=["logistics",...]}
```

## Anti-Cheat

All tools enforce:
- **10 tile reach distance** - can't interact with distant entities
- **No teleportation** - must walk
- **No fluidbox manipulation** - use pumps/pipes
- **No building on entities** - positions must be clear

## Error Handling

All tools return structured results:
```lua
{success=true, ...}   -- on success
{success=false, reason="description"}  -- on failure
```

Tools NEVER throw errors. Check `success` field!

## Logging

Tool usage is logged to:
- `logs/tool-usage.log` - all invocations
- `logs/tool-errors.log` - failures only

## Adding New Tools

Contact Tool Creator via mcp_agent_mail if you need new functionality.
