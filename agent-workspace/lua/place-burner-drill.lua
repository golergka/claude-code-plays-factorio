-- Place burner mining drill on a resource
-- The drill needs to be placed ON the resource patch

local pos = player.position

-- Find resources in reach
local function find_resource_in_reach(resource_name)
    local resources = surface.find_entities_filtered{
        position = pos,
        radius = player.reach_distance,
        name = resource_name
    }
    return resources
end

-- Check if we have a burner mining drill
local drill_count = player.get_item_count("burner-mining-drill")
if drill_count == 0 then
    rcon.print("ERROR: No burner-mining-drill in inventory!")
    return
end

-- Find coal to place drill on
local coal = find_resource_in_reach("coal")
if #coal == 0 then
    rcon.print("No coal in reach. Checking iron...")
    local iron = find_resource_in_reach("iron-ore")
    if #iron == 0 then
        rcon.print("No iron or coal in reach!")
        return
    end
end

-- Get the center of a good spot to place the drill
-- Burner drill is 2x2 and mines in front of it
local resource = coal[1] or find_resource_in_reach("iron-ore")[1]
local target_pos = {x = math.floor(resource.position.x) + 0.5, y = math.floor(resource.position.y) + 0.5}

-- Put drill in cursor
player.cursor_stack.set_stack{name = "burner-mining-drill", count = 1}

-- Try to place it
if player.can_build_from_cursor{position = target_pos} then
    player.build_from_cursor{position = target_pos}
    player.clear_cursor()
    rcon.print(string.format("SUCCESS: Placed burner-mining-drill at (%.1f, %.1f) on %s",
        target_pos.x, target_pos.y, resource.name))
else
    -- Try a few nearby positions
    local offsets = {{0,0}, {1,0}, {0,1}, {1,1}, {-1,0}, {0,-1}}
    local placed = false
    for _, offset in ipairs(offsets) do
        local try_pos = {x = target_pos.x + offset[1], y = target_pos.y + offset[2]}
        if player.can_build_from_cursor{position = try_pos} then
            player.build_from_cursor{position = try_pos}
            player.clear_cursor()
            rcon.print(string.format("SUCCESS: Placed burner-mining-drill at (%.1f, %.1f)",
                try_pos.x, try_pos.y))
            placed = true
            break
        end
    end
    if not placed then
        player.clear_cursor()
        rcon.print("FAILED: Could not place drill at any position near target")
    end
end
