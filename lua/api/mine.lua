-- lua/api/mine.lua
-- Mine resources or entities within reach
--
-- Set globals before running:
--   TARGET = resource/entity name (e.g., "iron-ore", "stone", "tree")
--   COUNT = how many to mine (default: 1, max: 50)
--
-- Usage: pnpm eval "TARGET='stone'; COUNT=10" && pnpm eval:file lua/api/mine.lua

(function()
    local target = TARGET
    local count = math.min(COUNT or 1, 50)

    if not target then
        return {success=false, reason="TARGET not set. Use: TARGET='iron-ore'"}
    end

    -- Find target entities within reach
    local entities = surface.find_entities_filtered{
        position = player.position,
        radius = player.reach_distance,
        name = target
    }

    if #entities == 0 then
        -- Try finding by type if name didn't work
        entities = surface.find_entities_filtered{
            position = player.position,
            radius = player.reach_distance,
            type = target
        }
    end

    if #entities == 0 then
        -- Check if there are any nearby but out of reach
        local nearby = surface.find_entities_filtered{
            position = player.position,
            radius = 50,
            name = target
        }
        if #nearby > 0 then
            local nearest = nearby[1]
            local dist = math.sqrt(
                (nearest.position.x - player.position.x)^2 +
                (nearest.position.y - player.position.y)^2
            )
            return {
                success = false,
                reason = "no " .. target .. " in reach. Nearest is " .. math.floor(dist) .. " tiles away at (" ..
                    math.floor(nearest.position.x) .. ", " .. math.floor(nearest.position.y) .. ")"
            }
        end
        return {success=false, reason="no " .. target .. " found nearby"}
    end

    -- Sort by distance
    table.sort(entities, function(a, b)
        local da = (a.position.x - player.position.x)^2 + (a.position.y - player.position.y)^2
        local db = (b.position.x - player.position.x)^2 + (b.position.y - player.position.y)^2
        return da < db
    end)

    -- Mine entities
    local mined = 0
    local item_name = target
    for i, entity in ipairs(entities) do
        if mined >= count then break end

        -- Check distance
        local dist = math.sqrt(
            (entity.position.x - player.position.x)^2 +
            (entity.position.y - player.position.y)^2
        )
        if dist <= player.reach_distance then
            local success = player.mine_entity(entity, true)
            if success then
                mined = mined + 1
                -- Try to determine what item we got
                if entity.prototype and entity.prototype.mineable_properties then
                    local products = entity.prototype.mineable_properties.products
                    if products and #products > 0 then
                        item_name = products[1].name or target
                    end
                end
            end
        end
    end

    if mined == 0 then
        return {success=false, reason="failed to mine any " .. target}
    end

    local total = player.get_item_count(item_name)

    return {
        success = true,
        mined = mined,
        item = item_name,
        total = total
    }
end)()
