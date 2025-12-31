-- Fuel a nearby stone furnace with coal
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

-- Check what fuel we have
local coal_count = player.get_item_count("coal")

if coal_count == 0 then
    rcon.print("No coal in inventory!")
    return
end

-- Insert up to 5 coal into furnace fuel slot
local fuel_to_add = math.min(coal_count, 5)
local inserted = furnace.insert{name = "coal", count = fuel_to_add}
if inserted > 0 then
    player.remove_item{name = "coal", count = inserted}
    rcon.print(string.format("Inserted %d coal into furnace at (%.1f, %.1f)",
        inserted, furnace.position.x, furnace.position.y))
else
    rcon.print("Could not insert coal into furnace")
end
