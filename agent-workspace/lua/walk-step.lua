-- Walk toward target with BUILT-IN TIMEOUT
-- Edit TARGET_X and TARGET_Y, then run repeatedly until ARRIVED!
-- TIMEOUT: Walking stops after ~2 seconds (120 ticks)
local TARGET_X = 40
local TARGET_Y = 28
local WALK_TIMEOUT = 30  -- ticks (0.5 seconds)

-- Initialize global storage if needed
if not global.walk_state then global.walk_state = {} end

local pos = player.position
local dx = TARGET_X - pos.x
local dy = TARGET_Y - pos.y
local distance = math.sqrt(dx * dx + dy * dy)

-- Check if we've arrived
if distance < player.reach_distance then
    player.walking_state = {walking = false}
    global.walk_state = {}
    rcon.print(string.format("ARRIVED! Pos: (%.1f, %.1f) Dist: %.1f", pos.x, pos.y, distance))
    return
end

-- Check if timeout exceeded
if global.walk_state.deadline and game.tick >= global.walk_state.deadline then
    player.walking_state = {walking = false}
    global.walk_state = {}
    rcon.print(string.format("TIMEOUT! Pos: (%.1f, %.1f) | Target: (%.1f, %.1f) | Dist: %.1f - Run again to continue",
        pos.x, pos.y, TARGET_X, TARGET_Y, distance))
    return
end

-- Calculate direction
local angle = math.atan2(dy, dx)
local direction, dir_name
if angle >= -math.pi/8 and angle < math.pi/8 then direction = defines.direction.east; dir_name = "east"
elseif angle >= math.pi/8 and angle < 3*math.pi/8 then direction = defines.direction.southeast; dir_name = "southeast"
elseif angle >= 3*math.pi/8 and angle < 5*math.pi/8 then direction = defines.direction.south; dir_name = "south"
elseif angle >= 5*math.pi/8 and angle < 7*math.pi/8 then direction = defines.direction.southwest; dir_name = "southwest"
elseif angle >= 7*math.pi/8 or angle < -7*math.pi/8 then direction = defines.direction.west; dir_name = "west"
elseif angle >= -7*math.pi/8 and angle < -5*math.pi/8 then direction = defines.direction.northwest; dir_name = "northwest"
elseif angle >= -5*math.pi/8 and angle < -3*math.pi/8 then direction = defines.direction.north; dir_name = "north"
else direction = defines.direction.northeast; dir_name = "northeast"
end

-- Check for obstacles ahead
local check_dist = 3
local check_x = pos.x + (dx / distance) * check_dist
local check_y = pos.y + (dy / distance) * check_dist
local tile = surface.get_tile(check_x, check_y)
local obstacle = ""
if tile then
    local tile_name = tile.name
    if tile_name:find("water") or tile_name:find("deepwater") then
        obstacle = " WATER AHEAD!"
    elseif tile_name:find("out%-of%-map") then
        obstacle = " EDGE OF MAP!"
    end
end
local entities_ahead = surface.find_entities_filtered{position = {check_x, check_y}, radius = 2, type = {"tree", "cliff"}}
if #entities_ahead > 0 then obstacle = obstacle .. " TREES/CLIFFS!" end

-- Start walking and set deadline
if not global.walk_state.deadline then
    global.walk_state.deadline = game.tick + WALK_TIMEOUT
end
player.walking_state = {walking = true, direction = direction}

rcon.print(string.format("WALKING %s | Pos: (%.1f, %.1f) | Target: (%.1f, %.1f) | Dist: %.1f%s",
    dir_name, pos.x, pos.y, TARGET_X, TARGET_Y, distance, obstacle))
