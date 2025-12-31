-- Mine stone in reach
local stones = surface.find_entities_filtered{position=player.position, radius=player.reach_distance, name='stone'}

if #stones == 0 then
    player.mining_state = {mining = false}
    rcon.print("No stone in reach!")
else
    local stone = stones[1]
    player.mining_state = {mining = true, position = stone.position}
    local stone_count = player.get_item_count("stone")
    rcon.print(string.format("Mining stone at (%.1f, %.1f) | Current stone in inventory: %d",
        stone.position.x, stone.position.y, stone_count))
end
