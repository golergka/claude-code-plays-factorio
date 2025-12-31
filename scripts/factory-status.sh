#!/bin/bash
# Get factory status in one line: techs, research, drills
# Usage: ./scripts/factory-status.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"
pnpm eval "
local done = 0
for _, t in pairs(force.technologies) do
    if t.researched then done=done+1 end
end

local research = 'none'
if force.current_research then
    research = force.current_research.name .. ' ' .. string.format('%.0f%%', force.research_progress * 100)
end

-- Count drills and their status
local drills = surface.find_entities_filtered{force=force, name='burner-mining-drill'}
local working = 0
local stopped = 0
for _, d in ipairs(drills) do
    if d.status == defines.entity_status.working then
        working = working + 1
    else
        stopped = stopped + 1
    end
end

rcon.print('Techs:' .. done .. ' Research:' .. research .. ' Drills:' .. working .. '/' .. (working+stopped) .. 'working')
" 2>/dev/null | tail -1
