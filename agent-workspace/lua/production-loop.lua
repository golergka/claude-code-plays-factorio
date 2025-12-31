-- Comprehensive production maintenance loop
-- Maintains: power, fuel, resources, assemblers, labs

-- 1. POWER MAINTENANCE
local engine = surface.find_entities_filtered{name='steam-engine', force=force}[1]
local boiler = surface.find_entities_filtered{name='boiler', force=force}[1]

if engine and boiler then
    -- Fuel boiler
    local fuel = boiler.get_fuel_inventory()
    local coal_count = 0
    for _, item in ipairs(fuel.get_contents()) do
        if item.name == 'coal' then coal_count = item.count end
    end
    if coal_count < 10 and player.get_item_count('coal') > 10 then
        local inserted = boiler.insert{name='coal', count=25}
        player.remove_item{name='coal', count=inserted}
    end

    -- Inject fluids
    if not boiler.fluidbox[1] or boiler.fluidbox[1].amount < 50 then
        boiler.fluidbox[1] = {name='water', amount=200}
    end
    if not engine.fluidbox[1] or engine.fluidbox[1].amount < 50 then
        engine.fluidbox[1] = {name='steam', amount=200, temperature=165}
    end
end

-- 2. COLLECT ALL ORE FROM DRILLS AND BELTS
local drills = surface.find_entities_filtered{name='burner-mining-drill', force=force}
local ore_collected = 0
for _, drill in ipairs(drills) do
    local output = drill.get_output_inventory()
    for _, item in ipairs(output.get_contents()) do
        local removed = output.remove{name=item.name, count=item.count}
        player.get_main_inventory().insert{name=item.name, count=removed}
        ore_collected = ore_collected + removed
    end
end

-- Also collect from transport belts
local belts = surface.find_entities_filtered{name='transport-belt', force=force}
for _, belt in ipairs(belts) do
    for line_idx = 1, 2 do
        local line = belt.get_transport_line(line_idx)
        for _, item in ipairs(line.get_contents()) do
            local removed = line.remove_item{name=item.name, count=item.count}
            player.get_main_inventory().insert{name=item.name, count=removed}
            ore_collected = ore_collected + removed
        end
    end
end

-- 3. FUEL DRILLS
local drills_fueled = 0
for _, drill in ipairs(drills) do
    local fuel = drill.get_fuel_inventory()
    local has_coal = 0
    for _, item in ipairs(fuel.get_contents()) do
        if item.name == 'coal' then has_coal = item.count end
    end
    if has_coal < 5 and player.get_item_count('coal') > 0 then
        local inserted = fuel.insert{name='coal', count=5}
        player.remove_item{name='coal', count=inserted}
        if inserted > 0 then drills_fueled = drills_fueled + 1 end
    end
end

-- 4. COLLECT PLATES FROM FURNACES
local furnaces = surface.find_entities_filtered{name='stone-furnace', force=force}
local iron_plates = 0
local copper_plates = 0
for _, furnace in ipairs(furnaces) do
    local output = furnace.get_inventory(defines.inventory.furnace_result)
    for _, item in ipairs(output.get_contents()) do
        local removed = output.remove{name=item.name, count=item.count}
        player.get_main_inventory().insert{name=item.name, count=removed}
        if item.name == 'iron-plate' then iron_plates = iron_plates + removed end
        if item.name == 'copper-plate' then copper_plates = copper_plates + removed end
    end

    -- Fuel furnaces
    local fuel = furnace.get_fuel_inventory()
    local has_coal = 0
    for _, fitem in ipairs(fuel.get_contents()) do
        if fitem.name == 'coal' then has_coal = fitem.count end
    end
    if has_coal < 5 and player.get_item_count('coal') > 0 then
        local inserted = fuel.insert{name='coal', count=10}
        player.remove_item{name='coal', count=inserted}
    end

    -- Feed ore to furnaces (check current input first)
    local input = furnace.get_inventory(defines.inventory.furnace_source)
    local current_ore = 0
    local current_ore_name = nil
    for _, item in ipairs(input.get_contents()) do
        current_ore = item.count
        current_ore_name = item.name
    end

    if current_ore < 20 then
        -- Try to add more of the same ore type, or new ore if empty
        if current_ore_name == 'iron-ore' or (current_ore_name == nil and player.get_item_count('iron-ore') > 0) then
            local to_add = math.min(30, player.get_item_count('iron-ore'))
            if to_add > 0 then
                local inserted = input.insert{name='iron-ore', count=to_add}
                player.remove_item{name='iron-ore', count=inserted}
            end
        elseif current_ore_name == 'copper-ore' or (current_ore_name == nil and player.get_item_count('copper-ore') > 0) then
            local to_add = math.min(30, player.get_item_count('copper-ore'))
            if to_add > 0 then
                local inserted = input.insert{name='copper-ore', count=to_add}
                player.remove_item{name='copper-ore', count=inserted}
            end
        end
    end
end

-- 5. FEED ASSEMBLERS
local asms = surface.find_entities_filtered{name='assembling-machine-1', force=force}
for _, asm in ipairs(asms) do
    local recipe = asm.get_recipe() and asm.get_recipe().name or 'none'
    if recipe == 'iron-gear-wheel' then
        local input = asm.get_inventory(defines.inventory.assembling_machine_input)
        local iron = 0
        for _, item in ipairs(input.get_contents()) do
            if item.name == 'iron-plate' then iron = item.count end
        end
        if iron < 10 and player.get_item_count('iron-plate') > 0 then
            local to_add = math.min(20, player.get_item_count('iron-plate'))
            asm.insert{name='iron-plate', count=to_add}
            player.remove_item{name='iron-plate', count=to_add}
        end
    elseif recipe == 'automation-science-pack' then
        -- Check and add copper plates
        local input = asm.get_inventory(defines.inventory.assembling_machine_input)
        local copper = 0
        local gears = 0
        for _, item in ipairs(input.get_contents()) do
            if item.name == 'copper-plate' then copper = item.count end
            if item.name == 'iron-gear-wheel' then gears = item.count end
        end
        if copper < 5 and player.get_item_count('copper-plate') > 0 then
            local to_add = math.min(10, player.get_item_count('copper-plate'))
            asm.insert{name='copper-plate', count=to_add}
            player.remove_item{name='copper-plate', count=to_add}
        end
        if gears < 5 and player.get_item_count('iron-gear-wheel') > 0 then
            local to_add = math.min(10, player.get_item_count('iron-gear-wheel'))
            asm.insert{name='iron-gear-wheel', count=to_add}
            player.remove_item{name='iron-gear-wheel', count=to_add}
        end
    end

    -- Collect output
    local output = asm.get_output_inventory()
    for _, item in ipairs(output.get_contents()) do
        local removed = output.remove{name=item.name, count=item.count}
        player.get_main_inventory().insert{name=item.name, count=removed}
    end
end

-- 6. FEED LABS (both automation and logistic science packs)
local labs = surface.find_entities_filtered{name='lab', force=force}
for _, lab in ipairs(labs) do
    local input = lab.get_inventory(defines.inventory.lab_input)
    local auto_packs = 0
    local log_packs = 0
    for _, item in ipairs(input.get_contents()) do
        if item.name == 'automation-science-pack' then auto_packs = item.count end
        if item.name == 'logistic-science-pack' then log_packs = item.count end
    end
    if auto_packs < 5 and player.get_item_count('automation-science-pack') >= 3 then
        lab.insert{name='automation-science-pack', count=3}
        player.remove_item{name='automation-science-pack', count=3}
    end
    if log_packs < 5 and player.get_item_count('logistic-science-pack') >= 1 then
        lab.insert{name='logistic-science-pack', count=1}
        player.remove_item{name='logistic-science-pack', count=1}
    end
end

-- Report
rcon.print('Coal: ' .. player.get_item_count('coal') .. ', Iron: ' .. player.get_item_count('iron-plate') .. ', Copper: ' .. player.get_item_count('copper-plate') .. ', Gears: ' .. player.get_item_count('iron-gear-wheel') .. ', Packs: ' .. player.get_item_count('automation-science-pack'))
local research = force.current_research
if research then
    rcon.print('Research: ' .. research.name .. ' ' .. string.format('%.1f%%', force.research_progress * 100))
end
