-- Example: Using safe interaction wrappers
-- Run: pnpm --prefix /Users/golergka/Projects/factorio-agent eval:file agent-workspace/lua/interact-example.lua

-- First, load the helpers
dofile("/Users/golergka/Projects/factorio-agent/agent-workspace/lua/safe-interact.lua")

-- Find nearest furnace
local furnace, msg = find_nearest("stone-furnace", 50)
rcon.print("Find furnace: " .. msg)

if furnace then
    -- Try to insert coal (will fail if too far)
    local result, err = safe_insert(furnace, {name="coal", count=5})
    if result then
        rcon.print("Inserted " .. result .. " coal")
    else
        rcon.print("BLOCKED: " .. err)
        rcon.print("You need to walk to position: " .. furnace.position.x .. ", " .. furnace.position.y)
    end
end
