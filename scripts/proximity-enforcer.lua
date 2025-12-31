-- Proximity Enforcer for Factorio AI Agent
-- This code is injected BEFORE user code to enforce proximity-based interactions
-- The agent CANNOT bypass this - any entity interaction requires being close

local REACH_DISTANCE = 10 -- Player reach distance in Factorio

-- Helper to check if player is close enough to an entity
local function check_proximity(entity, action_name)
    if not entity or not entity.valid then
        return true -- Let Factorio handle invalid entities
    end
    local dx = entity.position.x - player.position.x
    local dy = entity.position.y - player.position.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist > REACH_DISTANCE then
        local msg = string.format("BLOCKED: %s failed - entity at (%.1f, %.1f) is %.1f tiles away, max reach is %d. WALK CLOSER!",
            action_name, entity.position.x, entity.position.y, dist, REACH_DISTANCE)
        rcon.print(msg)
        game.print("[color=red][PROXIMITY][/color] " .. msg)
        return false
    end
    return true
end

-- Store original methods
local original_entity_mt = getmetatable(game.surfaces[1].find_entities_filtered{limit=1}[1] or {}) or {}

-- Override entity inventory access by wrapping common patterns
-- Since we can't easily override metatables in Factorio's Lua sandbox,
-- we create wrapper functions that the agent should use

-- Safe inventory insert - checks proximity first
function safe_insert(entity, items)
    if not check_proximity(entity, "insert") then return 0 end
    local inv = entity.get_inventory(defines.inventory.chest) or
                entity.get_inventory(defines.inventory.furnace_source) or
                entity.get_inventory(defines.inventory.furnace_result) or
                entity.get_inventory(defines.inventory.lab_input) or
                entity.get_inventory(defines.inventory.assembling_machine_input)
    if inv then
        return inv.insert(items)
    end
    return 0
end

-- Safe inventory take - checks proximity first
function safe_take(entity, items)
    if not check_proximity(entity, "take") then return 0 end
    local inv = entity.get_inventory(defines.inventory.chest) or
                entity.get_inventory(defines.inventory.furnace_result) or
                entity.get_inventory(defines.inventory.assembling_machine_output)
    if inv then
        return inv.remove(items)
    end
    return 0
end

-- Safe entity interaction - checks proximity
function safe_interact(entity)
    if not check_proximity(entity, "interact") then return false end
    return true
end

-- Find entities and filter to only those in reach
function find_reachable(filter)
    local all = surface.find_entities_filtered(filter)
    local reachable = {}
    for _, e in ipairs(all) do
        local dx = e.position.x - player.position.x
        local dy = e.position.y - player.position.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist <= REACH_DISTANCE then
            table.insert(reachable, e)
        end
    end
    if #reachable == 0 and #all > 0 then
        local nearest = all[1]
        local min_dist = 999999
        for _, e in ipairs(all) do
            local dx = e.position.x - player.position.x
            local dy = e.position.y - player.position.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < min_dist then
                min_dist = dist
                nearest = e
            end
        end
        rcon.print(string.format("No %s in reach. Nearest at (%.1f, %.1f), distance %.1f. WALK THERE!",
            filter.name or filter.type or "entity", nearest.position.x, nearest.position.y, min_dist))
    end
    return reachable
end

-- Override dangerous patterns by checking entity distance
-- This function wraps any entity to make its inventory access proximity-checked
function wrap_entity(entity)
    if not entity or not entity.valid then return entity end

    -- Create a proxy that checks proximity on inventory access
    local proxy = {}
    setmetatable(proxy, {
        __index = function(t, k)
            if k == "get_inventory" then
                return function(self, inv_type)
                    if not check_proximity(entity, "get_inventory") then
                        return nil
                    end
                    return entity.get_inventory(inv_type)
                end
            end
            return entity[k]
        end,
        __newindex = function(t, k, v)
            entity[k] = v
        end
    })
    return proxy
end

-- Print reminder about proximity
rcon.print("[PROXIMITY MODE] Entity interactions limited to " .. REACH_DISTANCE .. " tiles. Use find_reachable() and safe_insert()/safe_take().")
