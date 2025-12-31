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

-- Count burner drills
local burner_drills = surface.find_entities_filtered{force=force, name='burner-mining-drill'}
local burner_working = 0
for _, d in ipairs(burner_drills) do
    if d.status == defines.entity_status.working then burner_working = burner_working + 1 end
end

-- Count electric drills
local electric_drills = surface.find_entities_filtered{force=force, name='electric-mining-drill'}
local electric_working = 0
for _, d in ipairs(electric_drills) do
    if d.status == defines.entity_status.working then electric_working = electric_working + 1 end
end

local drill_status = 'Burner:' .. burner_working .. '/' .. #burner_drills
if #electric_drills > 0 then
    drill_status = drill_status .. ' Elec:' .. electric_working .. '/' .. #electric_drills
end

-- Count furnaces
local furnaces = surface.find_entities_filtered{force=force, name='stone-furnace'}
local furnace_working = 0
for _, f in ipairs(furnaces) do
    if f.status == defines.entity_status.working then furnace_working = furnace_working + 1 end
end

-- Count assemblers
local assemblers = surface.find_entities_filtered{force=force, type='assembling-machine'}
local assembler_working = 0
for _, a in ipairs(assemblers) do
    if a.status == defines.entity_status.working then assembler_working = assembler_working + 1 end
end

-- Power infrastructure
local boilers = surface.find_entities_filtered{force=force, name='boiler'}
local steam_engines = surface.find_entities_filtered{force=force, name='steam-engine'}

local status = 'Techs:' .. done .. ' ' .. research .. ' ' .. drill_status .. ' Furn:' .. furnace_working .. '/' .. #furnaces
if #assemblers > 0 then status = status .. ' Asm:' .. assembler_working .. '/' .. #assemblers end
if #boilers > 0 or #steam_engines > 0 then status = status .. ' Power:' .. #boilers .. 'B/' .. #steam_engines .. 'E' end

rcon.print(status)
" 2>/dev/null | tail -1
