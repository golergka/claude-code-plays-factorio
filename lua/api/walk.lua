-- lua/api/walk.lua
-- Walk in a direction for a duration
--
-- Set globals before running:
--   DIRECTION = "north"|"south"|"east"|"west"|"ne"|"nw"|"se"|"sw"
--   DURATION = seconds (default: 1, max: 5)
--
-- Usage: pnpm eval "DIRECTION='north'; DURATION=2" && pnpm eval:file lua/api/walk.lua

(function()
    local direction = DIRECTION or "north"
    local duration = math.min(DURATION or 1, 5)

    -- Direction mapping
    local dir_map = {
        north = defines.direction.north,
        south = defines.direction.south,
        east = defines.direction.east,
        west = defines.direction.west,
        ne = defines.direction.northeast,
        nw = defines.direction.northwest,
        se = defines.direction.southeast,
        sw = defines.direction.southwest,
        northeast = defines.direction.northeast,
        northwest = defines.direction.northwest,
        southeast = defines.direction.southeast,
        southwest = defines.direction.southwest
    }

    local dir = dir_map[direction]
    if not dir then
        return {success=false, reason="invalid direction: " .. tostring(direction)}
    end

    -- Store start position
    local start_pos = {x=player.position.x, y=player.position.y}

    -- Start walking
    player.walking_state = {walking=true, direction=dir}

    -- Schedule stop using global storage
    local ticks = math.floor(duration * 60)

    if not global.walking_state then
        global.walking_state = {}
    end

    global.walking_state[player.index] = {
        start_tick = game.tick,
        stop_tick = game.tick + ticks,
        direction = direction,
        start_position = start_pos
    }

    return {
        success = true,
        walking = true,
        direction = direction,
        duration = duration,
        position = start_pos,
        message = "Walking " .. direction .. " for " .. duration .. "s. Call status.lua with QUERY='walking' to check."
    }
end)()
