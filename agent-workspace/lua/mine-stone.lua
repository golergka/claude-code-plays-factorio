-- Mine stone in reach using mine_entity (mining_state doesn't work via RCON)
local stones = surface.find_entities_filtered{position=player.position, radius=player.reach_distance, name='stone'}

if #stones == 0 then
    rcon.print("No stone in reach!")
else
    -- Mine up to 10 stone instantly
    local mined = 0
    for i, stone in ipairs(stones) do
        if mined < 10 then
            player.mine_entity(stone, true)
            mined = mined + 1
        end
    end
    local stone_count = player.get_item_count("stone")
    rcon.print(string.format("Mined %d stone | Total in inventory: %d", mined, stone_count))
end
