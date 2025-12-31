-- Generic walk-to-target script
-- Edit TARGET_X and TARGET_Y before running
local TARGET_X = 14.5
local TARGET_Y = 58.5

local pos = player.position
local dx = TARGET_X - pos.x
local dy = TARGET_Y - pos.y
local distance = math.sqrt(dx * dx + dy * dy)

-- Calculate angle and pick direction (8 directions)
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

if distance < player.reach_distance then
    player.walking_state = {walking = false}
    rcon.print(string.format("ARRIVED! Distance: %.1f (within reach: %.1f)", distance, player.reach_distance))
else
    player.walking_state = {walking = true, direction = dir}
    rcon.print(string.format("Walking %s | Dist: %.1f | Pos: (%.1f, %.1f) -> (%.1f, %.1f)",
        dir_name, distance, pos.x, pos.y, TARGET_X, TARGET_Y))
end
