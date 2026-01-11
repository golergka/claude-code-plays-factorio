-- lua/api/craft.lua
-- Craft items
--
-- Set globals before running:
--   RECIPE = recipe name (e.g., "iron-gear-wheel", "stone-furnace")
--   CRAFT_COUNT = how many to craft (default: 1)
--
-- Usage: pnpm eval "RECIPE='iron-gear-wheel'; CRAFT_COUNT=5" && pnpm eval:file lua/api/craft.lua

(function()
    local recipe = RECIPE
    local count = CRAFT_COUNT or 1

    if not recipe then
        return {success=false, reason="RECIPE not set. Use: RECIPE='iron-gear-wheel'"}
    end

    -- Check if recipe exists and is enabled
    local recipe_proto = force.recipes[recipe]
    if not recipe_proto then
        return {success=false, reason="unknown recipe: " .. recipe}
    end
    if not recipe_proto.enabled then
        return {success=false, reason="recipe not researched: " .. recipe}
    end

    -- Check how many we can craft
    local craftable = player.get_craftable_count(recipe)
    if craftable < 1 then
        -- Get ingredients for error message
        local ingredients = {}
        for _, ing in ipairs(recipe_proto.ingredients) do
            local have = player.get_item_count(ing.name)
            local need = ing.amount * count
            table.insert(ingredients, ing.name .. " (have " .. have .. ", need " .. need .. ")")
        end
        return {
            success = false,
            reason = "missing ingredients for " .. recipe .. ": " .. table.concat(ingredients, ", ")
        }
    end

    -- Limit to what we can actually craft
    local to_craft = math.min(count, craftable)

    -- Start crafting
    local crafted = player.begin_crafting{recipe=recipe, count=to_craft}

    if crafted < 1 then
        return {success=false, reason="crafting failed for unknown reason"}
    end

    local queue = player.crafting_queue
    local queue_pos = queue and #queue or 1

    return {
        success = true,
        crafting = crafted,
        requested = count,
        queue_position = queue_pos,
        message = "Crafting " .. crafted .. " " .. recipe
    }
end)()
