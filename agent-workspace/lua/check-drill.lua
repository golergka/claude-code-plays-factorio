-- Check status of nearby burner mining drill
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

-- Check fuel inventory
local fuel_inv = drill.get_fuel_inventory()
local fuel_contents = fuel_inv and fuel_inv.get_contents() or {}

-- Check output (drills drop items on ground or into adjacent chest/belt)
-- The drill's output position is in front of it
local drop_pos = drill.drop_position

local result = string.format("Drill at (%.1f, %.1f)\n", drill.position.x, drill.position.y)
result = result .. string.format("Status: %s | Direction: %s\n", drill.status or "unknown", drill.direction)
result = result .. string.format("Drop position: (%.1f, %.1f)\n", drop_pos.x, drop_pos.y)
result = result .. "Fuel: "

local has_fuel = false
for _, item in ipairs(fuel_contents) do
    result = result .. string.format("%s: %d ", item.name, item.count)
    has_fuel = true
end
if not has_fuel then
    result = result .. "EMPTY!"
end

-- Check for items on ground near drop position
local items_on_ground = surface.find_entities_filtered{
    position = drop_pos,
    radius = 2,
    type = "item-entity"
}
result = result .. string.format("\nItems on ground: %d", #items_on_ground)

rcon.print(result)
