-- Place a stone furnace nearby
local pos = player.position

-- Check if we have a furnace
local furnace_count = player.get_item_count("stone-furnace")
if furnace_count == 0 then
    rcon.print("ERROR: No stone-furnace in inventory!")
    return
end

-- Find a clear spot to place it (not on resources)
local target_pos = {x = math.floor(pos.x) + 0.5, y = math.floor(pos.y) + 0.5}

-- Put furnace in cursor
player.cursor_stack.set_stack{name = "stone-furnace", count = 1}

-- Try to place it at a few positions
local offsets = {{0,0}, {1,0}, {0,1}, {-1,0}, {0,-1}, {2,0}, {0,2}, {-2,0}, {0,-2}}
local placed = false

for _, offset in ipairs(offsets) do
    local try_pos = {x = target_pos.x + offset[1], y = target_pos.y + offset[2]}
    if player.can_build_from_cursor{position = try_pos} then
        player.build_from_cursor{position = try_pos}
        player.clear_cursor()
        rcon.print(string.format("SUCCESS: Placed stone-furnace at (%.1f, %.1f)", try_pos.x, try_pos.y))
        placed = true
        break
    end
end

if not placed then
    player.clear_cursor()
    rcon.print("FAILED: Could not place furnace at any position near player")
end
