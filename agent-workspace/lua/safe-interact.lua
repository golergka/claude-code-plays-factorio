-- Safe interaction wrappers that enforce proximity checks
-- These prevent "cheating" by requiring the player to be near entities before interacting

-- Get player reach distance (typically ~6 tiles for hand interaction)
local reach = player.reach_distance or 6

-- Helper: Check if position is within reach
local function in_reach(entity_or_pos)
    local pos = entity_or_pos.position or entity_or_pos
    local px, py = player.position.x, player.position.y
    local ex, ey = pos.x, pos.y
    local dist = math.sqrt((px - ex)^2 + (py - ey)^2)
    return dist <= reach, dist
end

-- Safe insert: Only insert items if entity is within reach
-- Usage: safe_insert(entity, {name="coal", count=10})
function safe_insert(entity, items)
    if not entity or not entity.valid then
        return false, "invalid entity"
    end
    local ok, dist = in_reach(entity)
    if not ok then
        return false, string.format("too far (%.1f tiles, need <= %.1f) - walk closer first!", dist, reach)
    end
    local inserted = entity.insert(items)
    if inserted > 0 then
        player.remove_item{name=items.name, count=inserted}
    end
    return inserted, "ok"
end

-- Safe take: Only take items if entity is within reach
-- Usage: safe_take(entity, inventory_type)
function safe_take(entity, inv_type)
    if not entity or not entity.valid then
        return false, "invalid entity"
    end
    local ok, dist = in_reach(entity)
    if not ok then
        return false, string.format("too far (%.1f tiles, need <= %.1f) - walk closer first!", dist, reach)
    end
    local inv = entity.get_inventory(inv_type)
    if not inv then
        return false, "no inventory"
    end
    local taken = {}
    for name, count in pairs(inv.get_contents()) do
        local removed = inv.remove{name=name, count=count}
        if removed > 0 then
            player.insert{name=name, count=removed}
            taken[name] = removed
        end
    end
    return taken, "ok"
end

-- Safe build: Only build if position is within reach AND player has item
-- Usage: safe_build("stone-furnace", {x=10, y=20})
function safe_build(item_name, position)
    local ok, dist = in_reach(position)
    if not ok then
        return false, string.format("too far (%.1f tiles, need <= %.1f) - walk closer first!", dist, reach)
    end
    if player.get_item_count(item_name) < 1 then
        return false, "no " .. item_name .. " in inventory"
    end
    player.cursor_stack.set_stack{name=item_name, count=1}
    if not player.can_build_from_cursor{position=position} then
        player.clear_cursor()
        return false, "cannot build there (blocked or invalid)"
    end
    player.build_from_cursor{position=position}
    return true, "built " .. item_name
end

-- Safe mine: Only mine entity if within reach
-- Usage: safe_mine(entity)
function safe_mine(entity)
    if not entity or not entity.valid then
        return false, "invalid entity"
    end
    local ok, dist = in_reach(entity)
    if not ok then
        return false, string.format("too far (%.1f tiles, need <= %.1f) - walk closer first!", dist, reach)
    end
    local result = player.mine_entity(entity, true)
    return result, result and "mined" or "failed to mine"
end

-- Find nearest entity of type within radius, sorted by distance
-- Usage: find_nearest("stone-furnace", 50)
function find_nearest(name, radius)
    radius = radius or 50
    local entities = surface.find_entities_filtered{
        position=player.position,
        radius=radius,
        name=name
    }
    if #entities == 0 then
        return nil, "no " .. name .. " found within " .. radius .. " tiles"
    end
    -- Sort by distance
    local px, py = player.position.x, player.position.y
    table.sort(entities, function(a, b)
        local da = (a.position.x - px)^2 + (a.position.y - py)^2
        local db = (b.position.x - px)^2 + (b.position.y - py)^2
        return da < db
    end)
    local nearest = entities[1]
    local dist = math.sqrt((nearest.position.x - px)^2 + (nearest.position.y - py)^2)
    return nearest, string.format("found at (%.1f, %.1f), distance: %.1f", nearest.position.x, nearest.position.y, dist)
end

-- Report what's loaded
rcon.print("Safe interaction helpers loaded: safe_insert, safe_take, safe_build, safe_mine, find_nearest")
rcon.print("Player reach distance: " .. reach .. " tiles")
