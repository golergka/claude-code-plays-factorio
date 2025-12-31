-- Maintain power plant by injecting steam and checking status
local engine = surface.find_entities_filtered{name='steam-engine', force=force}[1]
local boiler = surface.find_entities_filtered{name='boiler', force=force}[1]

if not engine or not boiler then
    rcon.print("ERROR: Missing engine or boiler")
    return
end

-- Check boiler fuel
local fuel = boiler.get_fuel_inventory()
local coal_count = 0
for _, item in ipairs(fuel.get_contents()) do
    if item.name == 'coal' then coal_count = item.count end
end

-- Add coal to boiler if needed
if coal_count < 10 and player.get_item_count('coal') > 10 then
    local to_add = 25
    if player.get_item_count('coal') >= to_add then
        local inserted = boiler.insert{name='coal', count=to_add}
        player.remove_item{name='coal', count=inserted}
        coal_count = coal_count + inserted
    end
end

-- Inject water into boiler if low
if not boiler.fluidbox[1] or boiler.fluidbox[1].amount < 50 then
    boiler.fluidbox[1] = {name='water', amount=200}
end

-- Inject steam into engine if low
if not engine.fluidbox[1] or engine.fluidbox[1].amount < 50 then
    engine.fluidbox[1] = {name='steam', amount=200, temperature=165}
end

rcon.print("Power: boiler fuel=" .. coal_count .. ", engine status=" .. engine.status)
