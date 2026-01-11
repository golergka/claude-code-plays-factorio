-- Stop walking and find nearest stone
player.walking_state = {walking = false}

local pos = player.position
local stones = surface.find_entities_filtered{position=pos, radius=200, name='stone'}

if #stones == 0 then
    rcon.print("No stone found within 200 tiles")
else
    -- Find the closest one
    local nearest = nil
    local nearest_dist = math.huge

    for _, stone in ipairs(stones) do
        local dx = stone.position.x - pos.x
        local dy = stone.position.y - pos.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < nearest_dist then
            nearest = stone
            nearest_dist = dist
        end
    end

    rcon.print(string.format("Stopped. Position: (%.1f, %.1f) | Nearest stone at (%.1f, %.1f), distance: %.1f",
        pos.x, pos.y, nearest.position.x, nearest.position.y, nearest_dist))
end
