hud = {}
hud.widgets = {}

-- incremento = 202/286
local map = modules.game_interface.getMapPanel()

function HudModule.updatePosition(old, new)
    for k,v in pairs(hud.widgets) do
        v:setX(((583 - new.height)*(202/286)) + 200)
    end
end
function HudModule.online()
    map.onGeometryChange = HudModule.updatePosition
    g_ui.loadUI("hud")
end

function HudModule.offline()
    HudModule.clear()
end

function HudModule.addText(text, id, color)
    label = g_ui.createWidget("HUDLabel", map)
    if id then
        label:setId(id)
    else
        label:setId(#hud.widgets)
    end
    if color then
        if color == "red" then label:setColor("#FF0000") end
        if color == "green" then label:setColor("#00FF00") end
        if color == "blue" then label:setColor("#0000FF")end
        if color == "blue1" then label:setColor("#00BFFF") end
        if color == "yellow" then label:setColor("#FFFF00") end
    end
    label:setText(text)
    label:setX(((583 - map:getSize().height)*(202/286)) + 200)
    if #hud.widgets > 0 then
        label:addAnchor(AnchorTop, "prev", AnchorBottom)
    end
    label:hide()
    label:show()
    table.insert(hud.widgets, label)
    return label
end

function HudModule.addItem(id, count)
    if not id then
        return
    end
    local item = g_ui.createWidget("HUDItem", map)
    item:setItemId(id)
    item:setX(((583 - map:getSize().height)*(202/286)) + 200)
    if count then
        item:setText(tostring(count))
    end
    if #hud.widgets > 0 then
        item:addAnchor(AnchorTop, "prev", AnchorBottom)
    end
    item:hide()
    item:show()
    table.insert(hud.widgets, item)
    return item
end
function HudModule.clear()
    for k,v in pairs(hud.widgets) do
        v:destroy()
    end
    hud.widgets = {}
end