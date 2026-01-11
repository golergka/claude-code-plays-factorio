-- Diagnose and attempt to fix drill issues
-- This script checks all burner drills and reports their status
-- It also attempts basic fixes like adding fuel from player inventory

local drills = surface.find_entities_filtered{force=force, name='burner-mining-drill'}
local results = {}
local fixed = 0

for i, drill in ipairs(drills) do
    local status = drill.status
    local pos = drill.position
    local fuel_inv = drill.get_fuel_inventory()
    local fuel_count = 0
    if fuel_inv then
        local contents = fuel_inv.get_contents()
        fuel_count = contents['coal'] or contents['wood'] or 0
    end

    local issue = "unknown"
    local action = "none"

    -- Status codes:
    -- 1 = working
    -- 21 = waiting_for_target (no target entity)
    -- 34 = no_minable_resources (ore depleted or output full)
    -- 53 = no_fuel
    -- 54 = no_power

    if status == 1 then
        issue = "working"
    elseif status == 21 then
        issue = "waiting_for_target"
    elseif status == 34 then
        -- Check if output is blocked
        local output_inv = drill.get_output_inventory()
        if output_inv and output_inv.is_full() then
            issue = "output_full"
            -- Try to take items from output
            local taken = output_inv.get_contents()
            for name, count in pairs(taken) do
                local removed = output_inv.remove{name=name, count=count}
                if removed > 0 then
                    player.insert{name=name, count=removed}
                    action = "cleared_output_" .. name .. "_" .. removed
                    fixed = fixed + 1
                end
            end
        else
            issue = "no_minable_resources"
        end
    elseif status == 53 then
        issue = "no_fuel"
        -- Try to add coal from player inventory
        local player_coal = player.get_item_count('coal')
        if player_coal > 0 and fuel_inv then
            local to_add = math.min(player_coal, 10)
            local added = fuel_inv.insert{name='coal', count=to_add}
            if added > 0 then
                player.remove_item{name='coal', count=added}
                action = "added_coal_" .. added
                fixed = fixed + 1
            end
        else
            action = "need_coal_player_has_" .. player_coal
        end
    elseif status == 54 then
        issue = "no_power"
    end

    table.insert(results, string.format("Drill#%d@(%.0f,%.0f): %s fuel:%d action:%s",
        i, pos.x, pos.y, issue, fuel_count, action))
end

rcon.print("=== DRILL DIAGNOSTIC ===")
rcon.print("Total drills: " .. #drills .. ", Fixed: " .. fixed)
for _, r in ipairs(results) do
    rcon.print(r)
end
rcon.print("=== END DIAGNOSTIC ===")
