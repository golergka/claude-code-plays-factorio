-- lua/api/research.lua
-- Start or manage research
--
-- Set globals before running:
--   RESEARCH_ACTION = "start"|"queue"|"cancel"|"status" (default: status)
--   TECHNOLOGY = technology name (for start/queue)
--
-- Usage:
--   Status: pnpm eval:file lua/api/research.lua
--   Start: pnpm eval "RESEARCH_ACTION='start'; TECHNOLOGY='automation'" && pnpm eval:file lua/api/research.lua

(function()
    local action = RESEARCH_ACTION or "status"

    if action == "status" then
        local current = force.current_research
        local result = {
            success = true,
            current = current and {
                name = current.name,
                progress = force.research_progress,
                remaining = current.research_unit_count - math.floor(current.research_unit_count * force.research_progress)
            } or nil,
            queue_enabled = force.research_queue_enabled,
            completed_count = 0,
            available = {}
        }

        -- Count completed and list available
        for name, tech in pairs(force.technologies) do
            if tech.researched then
                result.completed_count = result.completed_count + 1
            elseif tech.enabled and not tech.researched then
                -- Check if prerequisites are met
                local prereqs_met = true
                for _, prereq in ipairs(tech.prerequisites) do
                    if not prereq.researched then
                        prereqs_met = false
                        break
                    end
                end
                if prereqs_met then
                    table.insert(result.available, {
                        name = tech.name,
                        cost = tech.research_unit_count
                    })
                end
            end
        end

        table.sort(result.available, function(a, b) return a.cost < b.cost end)
        -- Limit to 10 cheapest
        if #result.available > 10 then
            local limited = {}
            for i = 1, 10 do
                table.insert(limited, result.available[i])
            end
            result.available = limited
        end

        return result

    elseif action == "start" or action == "queue" then
        local tech_name = TECHNOLOGY
        if not tech_name then
            return {success=false, reason="TECHNOLOGY not set"}
        end

        local tech = force.technologies[tech_name]
        if not tech then
            return {success=false, reason="unknown technology: " .. tech_name}
        end

        if tech.researched then
            return {success=false, reason=tech_name .. " is already researched"}
        end

        -- Check prerequisites
        for _, prereq in ipairs(tech.prerequisites) do
            if not prereq.researched then
                return {
                    success = false,
                    reason = "prerequisite not researched: " .. prereq.name
                }
            end
        end

        -- Enable research queue
        force.research_queue_enabled = true

        -- Add to research
        local added = force.add_research(tech_name)

        return {
            success = added,
            technology = tech_name,
            cost = tech.research_unit_count,
            reason = not added and "failed to add research" or nil
        }

    elseif action == "cancel" then
        force.cancel_current_research()
        return {success=true, message="Research cancelled"}

    else
        return {success=false, reason="unknown action: " .. tostring(action)}
    end
end)()
