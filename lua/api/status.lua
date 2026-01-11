-- lua/api/status.lua
-- Query game state
--
-- Set QUERY global before running (optional):
--   QUERY = "position"|"inventory"|"nearby_resources"|"buildings"|"research"|"all"
--   RADIUS = number (default: 50)
--
-- Usage: pnpm eval:file lua/api/status.lua

(function()
    -- Parameters from globals (set before running)
    local query = QUERY or "all"
    local radius = RADIUS or 50

    local function get_position()
        return {x=player.position.x, y=player.position.y}
    end

    local function get_inventory()
        local inv = player.get_main_inventory()
        if not inv then return {} end
        return inv.get_contents()
    end

    local function get_nearby_resources()
        local resources = surface.find_entities_filtered{
            position = player.position,
            radius = radius,
            type = "resource"
        }
        local result = {}
        for _, r in ipairs(resources) do
            local dist = math.sqrt(
                (r.position.x - player.position.x)^2 +
                (r.position.y - player.position.y)^2
            )
            -- Group by name, show nearest
            if not result[r.name] or result[r.name].distance > dist then
                result[r.name] = {
                    name = r.name,
                    position = {x=r.position.x, y=r.position.y},
                    distance = math.floor(dist * 10) / 10,
                    amount = r.amount
                }
            end
        end
        -- Convert to array
        local arr = {}
        for _, v in pairs(result) do
            table.insert(arr, v)
        end
        table.sort(arr, function(a, b) return a.distance < b.distance end)
        return arr
    end

    local function get_buildings()
        local entities = surface.find_entities_filtered{
            position = player.position,
            radius = radius,
            force = force
        }
        local result = {}
        for _, e in ipairs(entities) do
            if e.type ~= "character" and e.type ~= "resource" then
                local dist = math.sqrt(
                    (e.position.x - player.position.x)^2 +
                    (e.position.y - player.position.y)^2
                )
                local status = "unknown"
                if e.status then
                    local status_names = {
                        [defines.entity_status.working] = "working",
                        [defines.entity_status.no_fuel] = "no_fuel",
                        [defines.entity_status.no_power] = "no_power",
                        [defines.entity_status.waiting_for_source_items] = "waiting_for_input",
                        [defines.entity_status.waiting_for_space_in_destination] = "output_full",
                    }
                    status = status_names[e.status] or tostring(e.status)
                end
                table.insert(result, {
                    name = e.name,
                    position = {x=e.position.x, y=e.position.y},
                    distance = math.floor(dist * 10) / 10,
                    status = status,
                    in_reach = dist <= player.reach_distance
                })
            end
        end
        table.sort(result, function(a, b) return a.distance < b.distance end)
        -- Limit to first 20
        if #result > 20 then
            local limited = {}
            for i = 1, 20 do
                table.insert(limited, result[i])
            end
            result = limited
        end
        return result
    end

    local function get_research()
        local current = force.current_research
        local result = {
            current = current and current.name or nil,
            progress = current and force.research_progress or 0,
            completed_count = 0
        }
        for name, tech in pairs(force.technologies) do
            if tech.researched then
                result.completed_count = result.completed_count + 1
            end
        end
        return result
    end

    -- Execute query
    if query == "position" then
        return get_position()
    elseif query == "inventory" then
        return get_inventory()
    elseif query == "nearby_resources" then
        return get_nearby_resources()
    elseif query == "buildings" then
        return get_buildings()
    elseif query == "research" then
        return get_research()
    elseif query == "all" then
        return {
            position = get_position(),
            inventory = get_inventory(),
            nearby_resources = get_nearby_resources(),
            research = get_research()
        }
    else
        return {error = "unknown query: " .. tostring(query)}
    end
end)()
