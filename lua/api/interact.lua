-- lua/api/interact.lua
-- Insert or remove items from buildings
--
-- Set globals before running:
--   ACTION = "insert" or "remove"
--   ENTITY_NAME = name of entity to interact with (finds nearest)
--   ITEM_NAME = item name for insert
--   ITEM_COUNT = count for insert (default: all available)
--   INVENTORY_TYPE = "source"|"result"|"fuel"|"input"|"output" for remove
--
-- Usage:
--   Insert: pnpm eval "ACTION='insert'; ENTITY_NAME='stone-furnace'; ITEM_NAME='coal'; ITEM_COUNT=5"
--   Remove: pnpm eval "ACTION='remove'; ENTITY_NAME='stone-furnace'; INVENTORY_TYPE='result'"

(function()
    local action = ACTION

    if action ~= "insert" and action ~= "remove" then
        return {success=false, reason="ACTION must be 'insert' or 'remove'"}
    end

    if not ENTITY_NAME then
        return {success=false, reason="ENTITY_NAME not set"}
    end

    -- Find nearest entity of this type within reach
    local entities = surface.find_entities_filtered{
        position = player.position,
        radius = player.reach_distance,
        name = ENTITY_NAME,
        force = force
    }

    if #entities == 0 then
        -- Check if any exist nearby but out of reach
        local nearby = surface.find_entities_filtered{
            position = player.position,
            radius = 50,
            name = ENTITY_NAME,
            force = force
        }
        if #nearby > 0 then
            local nearest = nearby[1]
            local dist = math.sqrt(
                (nearest.position.x - player.position.x)^2 +
                (nearest.position.y - player.position.y)^2
            )
            return {
                success = false,
                reason = "no " .. ENTITY_NAME .. " in reach. Nearest is " ..
                    math.floor(dist) .. " tiles away"
            }
        end
        return {success=false, reason="no " .. ENTITY_NAME .. " found"}
    end

    -- Sort by distance, pick nearest
    table.sort(entities, function(a, b)
        local da = (a.position.x - player.position.x)^2 + (a.position.y - player.position.y)^2
        local db = (b.position.x - player.position.x)^2 + (b.position.y - player.position.y)^2
        return da < db
    end)
    local entity = entities[1]

    -- Inventory type mapping
    local inv_map = {
        source = defines.inventory.furnace_source,
        result = defines.inventory.furnace_result,
        fuel = defines.inventory.fuel,
        input = defines.inventory.assembling_machine_input,
        output = defines.inventory.assembling_machine_output,
        chest = defines.inventory.chest,
        lab_input = defines.inventory.lab_input
    }

    if action == "insert" then
        if not ITEM_NAME then
            return {success=false, reason="ITEM_NAME not set for insert"}
        end

        local item_count = ITEM_COUNT or player.get_item_count(ITEM_NAME)
        if item_count < 1 then
            item_count = player.get_item_count(ITEM_NAME)
        end

        local have = player.get_item_count(ITEM_NAME)
        if have < 1 then
            return {success=false, reason="no " .. ITEM_NAME .. " in inventory"}
        end

        local to_insert = math.min(item_count, have)
        local inserted = entity.insert{name=ITEM_NAME, count=to_insert}

        if inserted > 0 then
            player.remove_item{name=ITEM_NAME, count=inserted}
        end

        return {
            success = inserted > 0,
            transferred = inserted,
            entity_position = {x=entity.position.x, y=entity.position.y},
            reason = inserted == 0 and "entity inventory full" or nil
        }

    else -- remove
        local inv_type = INVENTORY_TYPE or "result"
        local inv_id = inv_map[inv_type]

        local inv = entity.get_inventory(inv_id)
        if not inv then
            -- Try other common inventory types
            for name, id in pairs(inv_map) do
                inv = entity.get_inventory(id)
                if inv then break end
            end
        end

        if not inv then
            return {success=false, reason="entity has no accessible inventory"}
        end

        local contents = inv.get_contents()
        local total_removed = 0
        local removed_items = {}

        for item_name, count in pairs(contents) do
            local removed = inv.remove{name=item_name, count=count}
            if removed > 0 then
                player.insert{name=item_name, count=removed}
                removed_items[item_name] = removed
                total_removed = total_removed + removed
            end
        end

        return {
            success = total_removed > 0,
            transferred = total_removed,
            items = removed_items,
            entity_position = {x=entity.position.x, y=entity.position.y},
            reason = total_removed == 0 and "nothing to remove" or nil
        }
    end
end)()
