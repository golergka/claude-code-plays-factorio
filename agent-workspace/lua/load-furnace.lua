-- Load iron ore into a nearby stone furnace
local pos = player.position

local furnaces = surface.find_entities_filtered{
    position = pos,
    radius = player.reach_distance,
    name = "stone-furnace"
}

if #furnaces == 0 then
    rcon.print("No stone-furnace in reach!")
    return
end

local furnace = furnaces[1]

-- Check what iron ore we have
local iron_count = player.get_item_count("iron-ore")

if iron_count == 0 then
    rcon.print("No iron ore in inventory!")
    return
end

-- Insert iron ore into furnace input
local to_add = math.min(iron_count, 10)
local inserted = furnace.insert{name = "iron-ore", count = to_add}
if inserted > 0 then
    player.remove_item{name = "iron-ore", count = inserted}
    rcon.print(string.format("Inserted %d iron ore into furnace at (%.1f, %.1f)",
        inserted, furnace.position.x, furnace.position.y))
else
    rcon.print("Could not insert iron ore into furnace")
end
