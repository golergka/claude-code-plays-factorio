-- lua/api/build.lua
-- Place a building from inventory
--
-- Set globals before running:
--   ITEM = item name (e.g., "stone-furnace", "burner-mining-drill")
--   POS_X, POS_Y = absolute position (optional)
--   OFFSET_X, OFFSET_Y = relative to player (default: 0, 2)
--   BUILD_DIRECTION = "north"|"south"|"east"|"west" (default: north)
--
-- Usage: pnpm eval "ITEM='stone-furnace'; OFFSET_X=2; OFFSET_Y=0" && pnpm eval:file lua/api/build.lua

(function()
    local item = ITEM

    if not item then
        return {success=false, reason="ITEM not set. Use: ITEM='stone-furnace'"}
    end

    -- Calculate position
    local pos
    if POS_X and POS_Y then
        pos = {x=POS_X, y=POS_Y}
    else
        pos = {
            x = player.position.x + (OFFSET_X or 0),
            y = player.position.y + (OFFSET_Y or 2)
        }
    end

    -- Check if we have the item
    local count = player.get_item_count(item)
    if count < 1 then
        return {success=false, reason="no " .. item .. " in inventory (have " .. count .. ")"}
    end

    -- Check distance
    local dist = math.sqrt((pos.x - player.position.x)^2 + (pos.y - player.position.y)^2)
    if dist > player.reach_distance then
        return {
            success = false,
            reason = "position (" .. pos.x .. ", " .. pos.y .. ") is " ..
                math.floor(dist) .. " tiles away, max reach is " .. player.reach_distance
        }
    end

    -- Direction mapping
    local dir_map = {
        north = defines.direction.north,
        south = defines.direction.south,
        east = defines.direction.east,
        west = defines.direction.west
    }
    local direction = dir_map[BUILD_DIRECTION] or defines.direction.north

    -- Put item in cursor
    local cursor = player.cursor_stack
    if cursor.valid_for_read then
        player.clear_cursor()
    end

    local set_ok = cursor.set_stack{name=item, count=1}
    if not set_ok then
        return {success=false, reason="failed to put " .. item .. " in cursor"}
    end

    -- Check if we can build there
    local can_build = player.can_build_from_cursor{position=pos, direction=direction}
    if not can_build then
        player.clear_cursor()
        local blocking = surface.find_entities_filtered{
            position = pos,
            radius = 1
        }
        local blockers = {}
        for _, e in ipairs(blocking) do
            table.insert(blockers, e.name)
        end
        local reason = "cannot build at (" .. pos.x .. ", " .. pos.y .. ")"
        if #blockers > 0 then
            reason = reason .. " - blocked by: " .. table.concat(blockers, ", ")
        end
        return {success=false, reason=reason}
    end

    -- Build!
    player.build_from_cursor{position=pos, direction=direction}
    player.clear_cursor()

    return {
        success = true,
        entity = {
            name = item,
            position = {x=pos.x, y=pos.y}
        },
        message = "Built " .. item .. " at (" .. pos.x .. ", " .. pos.y .. ")"
    }
end)()
