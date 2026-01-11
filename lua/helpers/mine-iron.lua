-- Mine iron ore in reach using mine_entity (mining_state doesn't work via RCON)
local iron_ores = surface.find_entities_filtered{position=player.position, radius=player.reach_distance, name='iron-ore'}

if #iron_ores == 0 then
    rcon.print("No iron ore in reach!")
else
    -- Mine up to 10 iron ore instantly
    local mined = 0
    for i, ore in ipairs(iron_ores) do
        if mined < 10 then
            player.mine_entity(ore, true)
            mined = mined + 1
        end
    end
    local iron_count = player.get_item_count("iron-ore")
    rcon.print(string.format("Mined %d iron ore | Total in inventory: %d", mined, iron_count))
end
