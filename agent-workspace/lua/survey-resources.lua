-- Survey what resources are nearby
player.walking_state = {walking = false}

local pos = player.position
local radius = 100

local iron = surface.find_entities_filtered{position=pos, radius=radius, name='iron-ore'}
local coal = surface.find_entities_filtered{position=pos, radius=radius, name='coal'}
local copper = surface.find_entities_filtered{position=pos, radius=radius, name='copper-ore'}
local stone = surface.find_entities_filtered{position=pos, radius=radius, name='stone'}

local results = string.format("Position: (%.1f, %.1f)\n", pos.x, pos.y)
results = results .. string.format("Iron: %d | Coal: %d | Copper: %d | Stone: %d\n", #iron, #coal, #copper, #stone)

-- Find nearest of each type
local function nearest_pos(entities)
    if #entities == 0 then return "none" end
    local nearest = nil
    local nearest_dist = math.huge
    for _, e in ipairs(entities) do
        local dx = e.position.x - pos.x
        local dy = e.position.y - pos.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < nearest_dist then
            nearest = e
            nearest_dist = dist
        end
    end
    return string.format("(%.1f, %.1f) dist %.1f", nearest.position.x, nearest.position.y, nearest_dist)
end

results = results .. "Nearest iron: " .. nearest_pos(iron) .. "\n"
results = results .. "Nearest coal: " .. nearest_pos(coal) .. "\n"
results = results .. "Nearest copper: " .. nearest_pos(copper) .. "\n"
results = results .. "Nearest stone: " .. nearest_pos(stone)

rcon.print(results)
