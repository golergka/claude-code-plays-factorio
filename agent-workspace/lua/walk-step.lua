-- Walk one step towards target then STOP
-- Edit TARGET_X and TARGET_Y before running
local TARGET_X = 82.0
local TARGET_Y = 53.0

local pos = player.position
local dx = TARGET_X - pos.x
local dy = TARGET_Y - pos.y
local distance = math.sqrt(dx * dx + dy * dy)

-- Already arrived?
if distance < player.reach_distance then
    player.walking_state = {walking = false}
    rcon.print(string.format("ARRIVED! Dist: %.1f", distance))
    return
end

-- Calculate direction
local angle = math.atan2(dy, dx)
local dir
if angle >= -math.pi/8 and angle < math.pi/8 then
    dir = defines.direction.east
elseif angle >= math.pi/8 and angle < 3*math.pi/8 then
    dir = defines.direction.southeast
elseif angle >= 3*math.pi/8 and angle < 5*math.pi/8 then
    dir = defines.direction.south
elseif angle >= 5*math.pi/8 and angle < 7*math.pi/8 then
    dir = defines.direction.southwest
elseif angle >= 7*math.pi/8 or angle < -7*math.pi/8 then
    dir = defines.direction.west
elseif angle >= -7*math.pi/8 and angle < -5*math.pi/8 then
    dir = defines.direction.northwest
elseif angle >= -5*math.pi/8 and angle < -3*math.pi/8 then
    dir = defines.direction.north
else
    dir = defines.direction.northeast
end

-- Walk for exactly 30 ticks (~0.5 seconds, ~5 tiles)
local start_tick = game.tick
player.walking_state = {walking = true, direction = dir}

-- Busy-wait loop (only works in Factorio's Lua context)
while game.tick < start_tick + 30 do
    -- This creates a tiny delay per iteration
end

-- STOP after walking
player.walking_state = {walking = false}
local new_pos = player.position
local new_dist = math.sqrt((TARGET_X - new_pos.x)^2 + (TARGET_Y - new_pos.y)^2)
rcon.print(string.format("WALKED from (%.1f,%.1f) to (%.1f,%.1f) | Dist: %.1f",
    pos.x, pos.y, new_pos.x, new_pos.y, new_dist))
