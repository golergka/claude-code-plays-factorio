-- Mine iron ore in reach
local iron_ores = surface.find_entities_filtered{position=player.position, radius=player.reach_distance, name='iron-ore'}

if #iron_ores == 0 then
    player.mining_state = {mining = false}
    rcon.print("No iron ore in reach!")
else
    local iron = iron_ores[1]
    player.mining_state = {mining = true, position = iron.position}
    local iron_count = player.get_item_count("iron-ore")
    rcon.print(string.format("Mining iron ore at (%.1f, %.1f) | Current iron ore in inventory: %d",
        iron.position.x, iron.position.y, iron_count))
end
