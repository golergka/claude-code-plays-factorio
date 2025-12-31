-- Fuel a nearby burner mining drill
local pos = player.position

local drills = surface.find_entities_filtered{
    position = pos,
    radius = player.reach_distance,
    name = "burner-mining-drill"
}

if #drills == 0 then
    rcon.print("No burner-mining-drill in reach!")
    return
end

local drill = drills[1]

-- Check what fuel we have
local coal_count = player.get_item_count("coal")
local wood_count = player.get_item_count("wood")

local fuel_name = nil
local fuel_count = 0

if coal_count > 0 then
    fuel_name = "coal"
    fuel_count = math.min(coal_count, 10)
elseif wood_count > 0 then
    fuel_name = "wood"
    fuel_count = math.min(wood_count, 10)
else
    rcon.print("No fuel in inventory!")
    return
end

-- Insert fuel into drill
local inserted = drill.insert{name = fuel_name, count = fuel_count}
if inserted > 0 then
    player.remove_item{name = fuel_name, count = inserted}
    rcon.print(string.format("Inserted %d %s into drill at (%.1f, %.1f). Drill status: %s",
        inserted, fuel_name, drill.position.x, drill.position.y, drill.status and drill.status or "unknown"))
else
    rcon.print("Could not insert fuel into drill")
end
