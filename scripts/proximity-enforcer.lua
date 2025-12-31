-- Proximity Enforcer for Factorio AI Agent
-- Uses Lua's dynamic features to intercept entity methods at runtime
-- This replaces dangerous methods with proximity-checked versions

local REACH_DISTANCE = 10

-- Block teleportation by wrapping the player object
local real_player = player
player = setmetatable({}, {
    __index = function(t, k)
        if k == "teleport" then
            return function(...)
                local msg = "TELEPORTATION BLOCKED! You must WALK to your destination. No cheating!"
                rcon.print(msg)
                game.print("[color=red][BLOCKED][/color] " .. msg)
                error(msg)
            end
        end
        return real_player[k]
    end,
    __newindex = function(t, k, v)
        real_player[k] = v
    end
})

-- Helper to check distance
local function get_distance(entity)
    if not entity or not entity.valid then return 0 end
    local dx = entity.position.x - player.position.x
    local dy = entity.position.y - player.position.y
    return math.sqrt(dx*dx + dy*dy)
end

-- Create a proxy wrapper around an entity that enforces proximity
local function create_entity_proxy(entity)
    if not entity or not entity.valid then return entity end

    local proxy = {}
    setmetatable(proxy, {
        __index = function(t, k)
            local original = entity[k]

            -- Intercept ALL inventory access methods
            if k == "get_inventory" or k == "get_output_inventory" or
               k == "get_fuel_inventory" or k == "get_module_inventory" then
                return function(inv_type)
                    local dist = get_distance(entity)
                    if dist > REACH_DISTANCE then
                        local msg = string.format(
                            "PROXIMITY ERROR: %s at (%.1f, %.1f) is %.1f tiles away (max %d). WALK CLOSER!",
                            k, entity.position.x, entity.position.y, dist, REACH_DISTANCE)
                        rcon.print(msg)
                        game.print("[color=red][BLOCKED][/color] " .. msg)
                        error(msg)
                    end
                    if inv_type then
                        return entity[k](inv_type)
                    else
                        return entity[k]()
                    end
                end
            end

            -- Intercept direct insert on entity
            if k == "insert" then
                return function(items)
                    local dist = get_distance(entity)
                    if dist > REACH_DISTANCE then
                        local msg = string.format(
                            "PROXIMITY ERROR: insert at (%.1f, %.1f) is %.1f tiles away (max %d). WALK CLOSER!",
                            entity.position.x, entity.position.y, dist, REACH_DISTANCE)
                        rcon.print(msg)
                        error(msg)
                    end
                    return entity.insert(items)
                end
            end

            -- Intercept fluidbox access to prevent remote manipulation
            if k == "fluidbox" then
                local real_fluidbox = entity.fluidbox
                if not real_fluidbox then return nil end
                -- Return a proxy that checks proximity before allowing changes
                return setmetatable({}, {
                    __index = function(_, idx)
                        return real_fluidbox[idx]
                    end,
                    __newindex = function(_, idx, v)
                        local dist = get_distance(entity)
                        if dist > REACH_DISTANCE then
                            local msg = string.format(
                                "PROXIMITY ERROR: fluidbox at (%.1f, %.1f) is %.1f tiles away (max %d). WALK CLOSER!",
                                entity.position.x, entity.position.y, dist, REACH_DISTANCE)
                            rcon.print(msg)
                            error(msg)
                        end
                        real_fluidbox[idx] = v
                    end,
                    __len = function() return #real_fluidbox end
                })
            end

            -- For functions, wrap them to use the real entity
            if type(original) == "function" then
                return function(...)
                    return original(...)
                end
            end

            -- For properties, just return them
            return original
        end,
        __newindex = function(t, k, v)
            entity[k] = v
        end,
        -- Make pairs/ipairs work
        __pairs = function() return pairs(entity) end,
        __len = function() return #entity end
    })
    return proxy
end

-- Wrap an array of entities
local function wrap_entity_array(entities)
    local wrapped = {}
    for i, e in ipairs(entities) do
        wrapped[i] = create_entity_proxy(e)
    end
    return wrapped
end

-- Store the real surface
local real_surface = surface

-- Replace surface with a proxy that wraps returned entities
surface = setmetatable({}, {
    __index = function(t, k)
        local original = real_surface[k]

        -- Intercept find_entities_filtered to wrap results
        if k == "find_entities_filtered" then
            return function(filter)
                local entities = real_surface.find_entities_filtered(filter)
                return wrap_entity_array(entities)
            end
        end

        -- Intercept find_entity to wrap result
        if k == "find_entity" then
            return function(name, position)
                local entity = real_surface.find_entity(name, position)
                return create_entity_proxy(entity)
            end
        end

        -- Intercept find_entities to wrap results
        if k == "find_entities" then
            return function(area)
                local entities = real_surface.find_entities(area)
                return wrap_entity_array(entities)
            end
        end

        -- For other functions, pass through
        if type(original) == "function" then
            return function(...)
                return original(...)
            end
        end

        return original
    end
})

-- Also provide helper functions for convenience
function find_reachable(filter)
    local all = real_surface.find_entities_filtered(filter)
    local reachable = {}
    for _, e in ipairs(all) do
        if get_distance(e) <= REACH_DISTANCE then
            table.insert(reachable, create_entity_proxy(e))
        end
    end
    if #reachable == 0 and #all > 0 then
        local nearest = all[1]
        local min_dist = get_distance(nearest)
        for _, e in ipairs(all) do
            local d = get_distance(e)
            if d < min_dist then
                min_dist = d
                nearest = e
            end
        end
        rcon.print(string.format("No %s in reach. Nearest at (%.1f, %.1f), distance %.1f. WALK THERE!",
            filter.name or filter.type or "entity", nearest.position.x, nearest.position.y, min_dist))
    end
    return reachable
end

function check_proximity(entity, action_name)
    local dist = get_distance(entity)
    if dist > REACH_DISTANCE then
        rcon.print(string.format("BLOCKED: %s - entity at (%.1f, %.1f) is %.1f tiles away",
            action_name, entity.position.x, entity.position.y, dist))
        return false
    end
    return true
end

-- Safe wrappers that check proximity first (for explicit use)
function safe_insert(entity, items)
    if not check_proximity(entity, "insert") then return 0 end
    return entity.insert(items)
end

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

rcon.print("[PROXIMITY MODE] Methods intercepted. Inventory access requires being within " .. REACH_DISTANCE .. " tiles.")
