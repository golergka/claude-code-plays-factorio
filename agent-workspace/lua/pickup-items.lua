-- Pick up items on ground nearby
local pos = player.position

local items = surface.find_entities_filtered{
    position = pos,
    radius = player.reach_distance,
    type = "item-entity"
}

if #items == 0 then
    rcon.print("No items on ground in reach")
    return
end

local picked_up = {}
for _, item_entity in ipairs(items) do
    local stack = item_entity.stack
    if stack and stack.valid_for_read then
        local name = stack.name
        local count = stack.count
        -- Pick it up by inserting into player and destroying entity
        local inserted = player.insert{name = name, count = count}
        if inserted > 0 then
            item_entity.destroy()
            picked_up[name] = (picked_up[name] or 0) + inserted
        end
    end
end

local result = "Picked up: "
local any = false
for name, count in pairs(picked_up) do
    result = result .. string.format("%s x%d ", name, count)
    any = true
end
if not any then
    result = "Could not pick up any items"
end

rcon.print(result)
