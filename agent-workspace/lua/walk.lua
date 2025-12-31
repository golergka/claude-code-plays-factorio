-- Walk helper - walks towards a target in small steps
-- Usage: Set TARGET_X and TARGET_Y, then run this script repeatedly

local TARGET_X = 10  -- Edit this
local TARGET_Y = 54  -- Edit this

local pos = player.position
local dx = TARGET_X - pos.x
local dy = TARGET_Y - pos.y
local distance = math.sqrt(dx * dx + dy * dy)

-- Stop if close enough
if distance < player.reach_distance then
    player.walking_state = {walking = false}
    rcon.print(string.format("ARRIVED at (%.1f, %.1f) - distance %.1f", pos.x, pos.y, distance))
    return
end

-- Calculate direction based on angle
local angle = math.atan2(dy, dx)
local dir, dir_name

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

-- Start walking
player.walking_state = {walking = true, direction = dir}
rcon.print(string.format("Walking %s | Dist: %.1f | From (%.1f, %.1f) to (%d, %d)",
    dir_name, distance, pos.x, pos.y, TARGET_X, TARGET_Y))
