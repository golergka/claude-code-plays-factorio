-- Walk towards stone deposit at (-63.5, 83.5)
local target_x = -63.5
local target_y = 83.5

local pos = player.position
local dx = target_x - pos.x
local dy = target_y - pos.y
local distance = math.sqrt(dx * dx + dy * dy)

-- Calculate angle and pick direction
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

if distance < 3 then
    player.walking_state = {walking = false}
    rcon.print("Arrived at stone! Distance: " .. string.format("%.1f", distance))
else
    player.walking_state = {walking = true, direction = dir}
    rcon.print("Walking " .. dir_name .. " towards stone. Distance: " .. string.format("%.1f", distance) .. " | Pos: " .. string.format("%.1f, %.1f", pos.x, pos.y))
end
