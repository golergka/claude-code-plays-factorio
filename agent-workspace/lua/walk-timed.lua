-- Time-based walking helper
-- Walks in a direction for WALK_TICKS ticks (60 ticks = 1 second)
-- Uses global storage to track walking state

local WALK_TICKS = 120  -- 2 seconds of walking (~20 tiles)

-- Direction to walk (edit before running)
-- 0=north, 1=northeast, 2=east, 3=southeast, 4=south, 5=southwest, 6=west, 7=northwest
local DIRECTION = defines.direction.southeast

-- Check if we have a stored walking state
if not global.walk_state then
    global.walk_state = {}
end

local state = global.walk_state

-- If we're not currently walking, start walking
if not state.walking then
    state.walking = true
    state.start_tick = game.tick
    state.target_tick = game.tick + WALK_TICKS
    state.direction = DIRECTION
    player.walking_state = {walking = true, direction = DIRECTION}
    rcon.print(string.format("Started walking direction %d for %d ticks", DIRECTION, WALK_TICKS))
else
    -- Check if we've walked long enough
    if game.tick >= state.target_tick then
        player.walking_state = {walking = false}
        state.walking = false
        rcon.print(string.format("Stopped at (%.1f, %.1f) after %d ticks",
            player.position.x, player.position.y, game.tick - state.start_tick))
    else
        -- Still walking
        local remaining = state.target_tick - game.tick
        rcon.print(string.format("Still walking... %d ticks remaining. Pos: (%.1f, %.1f)",
            remaining, player.position.x, player.position.y))
    end
end
