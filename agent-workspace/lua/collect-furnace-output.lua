-- Collect output from a nearby stone furnace
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

-- Get the output inventory
local output = furnace.get_inventory(defines.inventory.furnace_result)
if not output then
    rcon.print("Could not access furnace output inventory")
    return
end

local contents = output.get_contents()
local collected = {}

for _, item in ipairs(contents) do
    local name = item.name
    local count = item.count
    local taken = output.remove{name=name, count=count}
    if taken > 0 then
        player.insert{name=name, count=taken}
        collected[name] = (collected[name] or 0) + taken
    end
end

local result = "Collected: "
local any = false
for name, count in pairs(collected) do
    result = result .. string.format("%s x%d ", name, count)
    any = true
end

if not any then
    -- Check input and fuel status
    local fuel = furnace.get_fuel_inventory()
    local fuel_contents = fuel and fuel.get_contents() or {}
    local input = furnace.get_inventory(defines.inventory.furnace_source)
    local input_contents = input and input.get_contents() or {}

    result = "No output yet. Status: " .. (furnace.status or "unknown")
    result = result .. " | Fuel: "
    for _, item in ipairs(fuel_contents) do
        result = result .. string.format("%s x%d ", item.name, item.count)
    end
    result = result .. "| Input: "
    for _, item in ipairs(input_contents) do
        result = result .. string.format("%s x%d ", item.name, item.count)
    end
end

rcon.print(result)
