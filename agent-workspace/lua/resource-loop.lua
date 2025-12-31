-- Resource management loop (no teleporting - directly manages entity inventories)
-- Collects from coal drills, distributes fuel, collects plates

local drills = surface.find_entities_filtered{name='burner-mining-drill', force=force}
local furnaces = surface.find_entities_filtered{name='stone-furnace', force=force}

-- Separate drills by what they mine
local coal_drills = {}
local iron_drills = {}
local copper_drills = {}

for _, d in ipairs(drills) do
    local target = d.mining_target
    if target then
        if target.name == 'coal' then table.insert(coal_drills, d)
        elseif target.name == 'iron-ore' then table.insert(iron_drills, d)
        elseif target.name == 'copper-ore' then table.insert(copper_drills, d)
        end
    end
end

-- Step 1: Collect coal from coal drill outputs
local coal_pool = 0
for _, d in ipairs(coal_drills) do
    local output = d.get_output_inventory()
    for _, item in ipairs(output.get_contents()) do
        if item.name == 'coal' then
            coal_pool = coal_pool + output.remove{name='coal', count=item.count}
        end
    end
end

-- Step 2: Fuel all drills that need it
local drills_fueled = 0
for _, d in ipairs(drills) do
    local fuel = d.get_fuel_inventory()
    local needs_fuel = true
    for _, item in ipairs(fuel.get_contents()) do
        if item.name == 'coal' and item.count >= 3 then
            needs_fuel = false
            break
        end
    end
    if needs_fuel and coal_pool >= 5 then
        fuel.insert{name='coal', count=5}
        coal_pool = coal_pool - 5
        drills_fueled = drills_fueled + 1
    end
end

-- Step 3: Fuel furnaces that need it
local furnaces_fueled = 0
for _, f in ipairs(furnaces) do
    local fuel = f.get_fuel_inventory()
    local needs_fuel = true
    for _, item in ipairs(fuel.get_contents()) do
        if item.name == 'coal' and item.count >= 5 then
            needs_fuel = false
            break
        end
    end
    if needs_fuel and coal_pool >= 10 then
        fuel.insert{name='coal', count=10}
        coal_pool = coal_pool - 10
        furnaces_fueled = furnaces_fueled + 1
    end
end

-- Step 4: Collect ore from iron/copper drills, ground items, and feed to furnaces
local iron_ore = 0
local copper_ore = 0

-- Collect from drill outputs
for _, d in ipairs(iron_drills) do
    local output = d.get_output_inventory()
    for _, item in ipairs(output.get_contents()) do
        if item.name == 'iron-ore' then
            iron_ore = iron_ore + output.remove{name='iron-ore', count=item.count}
        end
    end
end

for _, d in ipairs(copper_drills) do
    local output = d.get_output_inventory()
    for _, item in ipairs(output.get_contents()) do
        if item.name == 'copper-ore' then
            copper_ore = copper_ore + output.remove{name='copper-ore', count=item.count}
        end
    end
end

-- ALSO collect from ground items
local ground_items = surface.find_entities_filtered{type='item-entity'}
for _, item in ipairs(ground_items) do
    local name = item.stack.name
    local count = item.stack.count
    if name == 'iron-ore' then
        iron_ore = iron_ore + count
        item.destroy()
    elseif name == 'copper-ore' then
        copper_ore = copper_ore + count
        item.destroy()
    elseif name == 'coal' then
        coal_pool = coal_pool + count
        item.destroy()
    end
end

-- Feed ore to furnaces (first 2 for iron, last 2 for copper)
for i, f in ipairs(furnaces) do
    local input = f.get_inventory(defines.inventory.furnace_source)
    if i <= 2 and iron_ore > 0 then
        local inserted = input.insert{name='iron-ore', count=math.min(iron_ore, 20)}
        iron_ore = iron_ore - inserted
    elseif i > 2 and copper_ore > 0 then
        local inserted = input.insert{name='copper-ore', count=math.min(copper_ore, 20)}
        copper_ore = copper_ore - inserted
    end
end

-- Step 5: Collect plates from furnaces and add to player inventory
local iron_plates = 0
local copper_plates = 0

for _, f in ipairs(furnaces) do
    local output = f.get_inventory(defines.inventory.furnace_result)
    for _, item in ipairs(output.get_contents()) do
        if item.name == 'iron-plate' then
            local taken = output.remove{name='iron-plate', count=item.count}
            player.insert{name='iron-plate', count=taken}
            iron_plates = iron_plates + taken
        elseif item.name == 'copper-plate' then
            local taken = output.remove{name='copper-plate', count=item.count}
            player.insert{name='copper-plate', count=taken}
            copper_plates = copper_plates + taken
        end
    end
end

-- Step 6: Report status
local active_drills = 0
for _, d in ipairs(drills) do
    local fuel = d.get_fuel_inventory()
    if not fuel.is_empty() then active_drills = active_drills + 1 end
end

rcon.print('Coal: collected=' .. (coal_pool + drills_fueled*5 + furnaces_fueled*10) .. ', used=' .. (drills_fueled*5 + furnaces_fueled*10) .. ', remaining=' .. coal_pool)
rcon.print('Ore: iron=' .. iron_ore .. ', copper=' .. copper_ore)
rcon.print('Plates collected: iron=' .. iron_plates .. ', copper=' .. copper_plates)
rcon.print('Fueled: ' .. drills_fueled .. ' drills, ' .. furnaces_fueled .. ' furnaces. Active drills: ' .. active_drills .. '/' .. #drills)
