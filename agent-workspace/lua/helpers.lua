-- Factorio AI Agent Helper Functions
-- This file contains reusable helper functions for the AI agent

-- Walk towards a target position
-- Takes target_x and target_y coordinates and sets walking_state in the appropriate direction
-- Returns the direction being walked and distance to target
function walk_towards(target_x, target_y)
    local pos = player.position
    local dx = target_x - pos.x
    local dy = target_y - pos.y
    local distance = math.sqrt(dx * dx + dy * dy)

    -- If we're close enough, stop walking
    if distance < 0.5 then
        player.walking_state = {walking = false}
        return "arrived", distance
    end

    -- Determine the best direction (8 directions available)
    local dir
    local dir_name

    -- Calculate angle and pick closest direction
    local angle = math.atan2(dy, dx)  -- radians, 0 = east, pi/2 = south

    -- Convert to 8 directions (each 45 degrees = pi/4 radians)
    -- Factorio: north=0, northeast=1, east=2, southeast=3, south=4, southwest=5, west=6, northwest=7
    -- atan2: east=0, south=pi/2, west=pi/-pi, north=-pi/2

    if angle >= -math.pi/8 and angle < math.pi/8 then
        dir = defines.direction.east
        dir_name = "east"
    elseif angle >= math.pi/8 and angle < 3*math.pi/8 then
        dir = defines.direction.southeast
        dir_name = "southeast"
    elseif angle >= 3*math.pi/8 and angle < 5*math.pi/8 then
        dir = defines.direction.south
        dir_name = "south"
    elseif angle >= 5*math.pi/8 and angle < 7*math.pi/8 then
        dir = defines.direction.southwest
        dir_name = "southwest"
    elseif angle >= 7*math.pi/8 or angle < -7*math.pi/8 then
        dir = defines.direction.west
        dir_name = "west"
    elseif angle >= -7*math.pi/8 and angle < -5*math.pi/8 then
        dir = defines.direction.northwest
        dir_name = "northwest"
    elseif angle >= -5*math.pi/8 and angle < -3*math.pi/8 then
        dir = defines.direction.north
        dir_name = "north"
    else
        dir = defines.direction.northeast
        dir_name = "northeast"
    end

    player.walking_state = {walking = true, direction = dir}

    return dir_name, distance
end

-- Stop walking
function stop_walking()
    player.walking_state = {walking = false}
    return "stopped"
end

-- Get distance to a position
function distance_to(target_x, target_y)
    local pos = player.position
    local dx = target_x - pos.x
    local dy = target_y - pos.y
    return math.sqrt(dx * dx + dy * dy)
end

-- Check if position is within reach
function in_reach(target_x, target_y)
    return distance_to(target_x, target_y) <= player.reach_distance
end

-- Find nearest entity of a given type/name
function find_nearest(filter)
    filter.position = player.position
    filter.radius = filter.radius or 100
    local entities = surface.find_entities_filtered(filter)

    if #entities == 0 then
        return nil
    end

    local nearest = nil
    local nearest_dist = math.huge

    for _, entity in ipairs(entities) do
        local dist = distance_to(entity.position.x, entity.position.y)
        if dist < nearest_dist then
            nearest = entity
            nearest_dist = dist
        end
    end

    return nearest, nearest_dist
end

-- Print current status (position, inventory summary)
function status()
    local pos = player.position
    local inv = player.get_main_inventory()
    local contents = inv and inv.get_contents() or {}
    local item_count = 0
    for _, _ in pairs(contents) do
        item_count = item_count + 1
    end

    return string.format(
        "Position: (%.1f, %.1f) | Items: %d types | Reach: %.1f",
        pos.x, pos.y, item_count, player.reach_distance
    )
end

-- Return confirmation that helpers loaded
rcon.print("helpers.lua loaded successfully")
