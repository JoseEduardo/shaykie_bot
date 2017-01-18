--[[
  @Authors: Ben Dol (BeniS)
  @Details: 
]]

PvpModule = {}

-- load module events
dofiles('events')

local Panel = {
  --
}

local UI = {}
local playerPush = {}

function PvpModule.getPanel() return Panel end
function PvpModule.setPanel(panel) Panel = panel end

function PvpModule.init()
  -- create tab
  local botTabBar = ShaykieBot.window:getChildById('botTabBar')
  local tab = botTabBar:addTab(tr('PvP'))

  local tabPanel = botTabBar:getTabPanel(tab)
  local tabBuffer = tabPanel:getChildById('tabBuffer')
  Panel = g_ui.loadUI('pvp.otui', tabBuffer)

  PvpModule.parentUI = ShaykieBot.window
  PvpModule.loadUI(Panel)

  -- register module
  Modules.registerModule(PvpModule)

  PvpModule.bindHandlers()
end

function PvpModule.loadUI(panel)
  UI = {
    AntiPush = panel:recursiveGetChildById('AntiPush'),
    HealList = panel:recursiveGetChildById('HealList'),
    HealBar = panel:recursiveGetChildById('HealBar'),

    AutoManaShield = panel:recursiveGetChildById('AutoManaShield'),
    HealthBarMin = panel:recursiveGetChildById('HealthBarMin'),
    HealthBarMax = panel:recursiveGetChildById('HealthBarMax')
  }
end

function PvpModule.moveAllFromStack(direction)
  if not g_game.isOnline() then
    return
  end

  local player = g_game.getLocalPlayer()
  local playerPos = player:getPosition()
  
  local steps = 1
  if direction == 'WEST' then
    playerPos.x = playerPos.x - steps
  elseif direction == 'EAST' then
    playerPos.x = playerPos.x + steps
  elseif direction == 'NORTH' then
    playerPos.y = playerPos.y - steps
  elseif direction == 'SOUTH' then
    playerPos.y = playerPos.y + steps
  elseif direction == 'NORTHWEST' then
    playerPos.x = playerPos.x - steps
    playerPos.y = playerPos.y - steps
  elseif direction == 'NORTHEAST' then
    playerPos.x = playerPos.x + steps
    playerPos.y = playerPos.y - steps
  elseif direction == 'SOUTHWEST' then
    playerPos.x = playerPos.x - steps
    playerPos.y = playerPos.y + steps
  elseif direction == 'SOUTHEAST' then
    playerPos.x = playerPos.x + steps
    playerPos.y = playerPos.y + steps
  end

  local tile = g_map.getTile(playerPos)
  local items = tile:getThings()
  local playerToMove = nil

  for _, item in ipairs(items) do
    local mousePosition = g_window.getMousePosition()
    local mousePositionWgt = modules.game_interface.getRootPanel():recursiveGetChildByPos(mousePosition, false)
    if mousePositionWgt then
      local toTile = mousePositionWgt:getTile(mousePosition)
      if toTile then
        local count = 1
        if not item:isCreature() then
          count = item:getCount()
        else
          playerToMove = item
        end
        if item:getId() == 3043 then
          local toPos = {x=65535, y=64, z=0}
          g_game.move(item, toPos, count)
        else
          g_game.move(item, toTile:getPosition(), count)
        end
      end
    end
  end

  if playerToMove ~= nil then 
    playerPush = {
      targetPos = playerPos,
      creatureName = playerToMove:getName(),
      posPlayer = player:getPosition()
    }
  end
end

function PvpModule.bindHandlers()
  g_keyboard.bindKeyPress('Shift+Numpad2', function() PvpModule.moveAllFromStack('SOUTH') end)
  g_keyboard.bindKeyPress('Shift+Numpad8', function() PvpModule.moveAllFromStack('NORTH')end)
  g_keyboard.bindKeyPress('Shift+Numpad4', function() PvpModule.moveAllFromStack('WEST') end)
  g_keyboard.bindKeyPress('Shift+Numpad6', function() PvpModule.moveAllFromStack('EAST')end)
  g_keyboard.bindKeyPress('Shift+Numpad1', function() PvpModule.moveAllFromStack('SOUTHWEST') end)
  g_keyboard.bindKeyPress('Shift+Numpad7', function() PvpModule.moveAllFromStack('NORTHWEST')end)
  g_keyboard.bindKeyPress('Shift+Numpad3', function() PvpModule.moveAllFromStack('SOUTHEAST') end)
  g_keyboard.bindKeyPress('Shift+Numpad9', function() PvpModule.moveAllFromStack('NORTHEAST')end)

  g_keyboard.bindKeyPress('Ctrl+3', function()
    if not g_game.isOnline() then
      return
    end

    local mousePosition = g_window.getMousePosition()
    local mousePositionWgt = modules.game_interface.getRootPanel():recursiveGetChildByPos(mousePosition, false)
    if mousePositionWgt then
      local tileCreature = mousePositionWgt:getTile(mousePosition)
      local things =  tileCreature:getThings()
      for _, thing in ipairs(things) do
        local count = 1
        if thing:getCount() ~= nil then
          count = thing:getCount()
        end

        local origPos = tileCreature:getPosition()
        origPos.x = origPos.x+1
        g_game.move(thing, origPos, count)

        origPos.y = origPos.y+1
        g_game.move(thing, origPos, count)

        origPos.x = origPos.x-2
        g_game.move(thing, origPos, count)

        origPos.y = origPos.y-2
        g_game.move(thing, origPos, count)
      end
    end
  end)

  g_keyboard.bindKeyPress('Ctrl+2', function()
    if not g_game.isOnline() then
      return
    end

    if UI.AntiPush:isChecked() then
      local player = g_game.getLocalPlayer()
      local mypos = player:getPosition()
      local tile = g_map.getTile(mypos)
      local bp = player:getInventoryItem(InventorySlotBack)
      local GP = 3031
      local Worm = 3492
      local GPNABP = player:getItem(GP)
      local WormNaBP = player:getItem(Worm)
      local verificaSQM = tile:getTopMoveThing():getId()
      
      if GPNABP ~= nil then
        if verificaSQM ~= GP then
          g_game.move(GPNABP, mypos, 1)
        else
          g_game.move(WormNaBP, mypos, 1)
        end
      end
    end
  end)

  g_keyboard.bindKeyPress('Shift+Numpad5', function()
    if not g_game.isOnline() then
      return
    end

    local player = g_game.getLocalPlayer()
    local mypos = player:getPosition()
    local tile = g_map.getTile(mypos)
    local items = tile:getItems()

    for _, item in ipairs(items) do
      if not item:isNotMoveable() then

        if item:getId() == 3043 then
          local toPos = {x=65535, y=64, z=0}
          g_game.move(item, toPos, item:getCount())
        else
          local mousePosition = g_window.getMousePosition()
          local mousePositionWgt = modules.game_interface.getRootPanel():recursiveGetChildByPos(mousePosition, false)
          if mousePositionWgt then
            local toTile = mousePositionWgt:getTile(mousePosition)
            if toTile then
              g_game.move(item, toTile:getPosition(), item:getCount())
            end
          end
        end
      end
    end
  end)

  modules.game_interface.addMenuHook("siobot", tr("Add to sio"), 
    function(menuPosition, lookThing, useThing, creatureThing)
      if creatureThing ~= nil then
        PvpModule.addCreatureToSio(creatureThing:getId(), creatureThing:getName())
      end
    end,
    function(menuPosition, lookThing, useThing, creatureThing)
      return lookThing ~= nil and lookThing:getTile() ~= nil
    end)  

  connect(Creature, {
    onHealthPercentChange = onCreatureHealthPercentChange
  })

  connect(Creature, {
    onPositionChange = onMovePlayerDest
  })

  connect(g_game, {
    onAddThingInMap = onCreateItemMap
  })


  connect(LocalPlayer, {
   onHealthChange = activeManaShield
  })

end

function PvpModule.onCreateItemMap(thing, pos)
  if thing:isItem() then
    print(thing, pos)
  end
end

function PvpModule.terminate()
  disconnect(Creature, {
    onHealthPercentChange = onCreatureHealthPercentChange
  })

  disconnect(Creature, {
    onPositionChange = onMovePlayerDest
  })

  disconnect(g_game, {
    onAddThingInMap = onCreateItemMap
  })

  disconnect(LocalPlayer, {
    onHealthChange = activeManaShield
  })

  modules.game_interface.removeMenuHook("siobot", tr("Add to sio"))
  PvpModule.stop()

  Panel:destroy()
  Panel = nil
end

function onCreatureHealthPercentChange(creature, health)
  if not g_game.isOnline() then
    return
  end

  if creature ~= nil then
    if PvpModule.checkInNamesForSio(creature:getName()) then
      PvpModule.doHealFriend(creature);
    end
  end
end

function onMovePlayerDest(creature, newPos, oldPos)
  if not g_game.isOnline() then
    return
  end
  if playerPush.creatureName == nil then
    return false
  end

  if creature ~= nil then
    if creature:getName() ~= playerPush.creatureName then
      return false
    end

    local player = g_game.getLocalPlayer()
    local posPlayer = player:getPosition()
    if posPlayer.x ~= playerPush.posPlayer.x or posPlayer.y ~= playerPush.posPlayer.y or posPlayer.z ~= playerPush.posPlayer.z then
      return false
    end

    player:autoWalk( playerPush.targetPos )
    playerPush = {}
  end

end

function PvpModule.checkCreatures()
  if not g_game.isOnline() then
    return
  end

  local player = g_game.getLocalPlayer()
  local spectators = g_map.getSpectators(player:getPosition(), false)
  for _, creature in ipairs(spectators) do
    if not creature:isLocalPlayer() and PvpModule.checkInNamesForSio(creture:getName()) then
      PvpModule.doHealFriend(creature);
    end
  end
end

function PvpModule.checkInNamesForSio(name)
  local t = UI.HealList:getChildren()
  for idx,child in pairs(t) do
    if child:getText() == name then
      return true
    end
  end

  return false
end

function PvpModule.doHealFriend(creature)
    local healthValue = UI.HealBar:getValue()

    local delay = 0
    if creature:getHealthPercent() < healthValue then
      g_game.talk('exura sio "'..creature:getName())
      delay = Helper.getSpellDelay('exura sio')
    end

end

function PvpModule.equipeManaShieldRing()
 if g_game.isOnline() then
    local player = g_game.getLocalPlayer()
    local selectedItem = 3052

    local item = player:getItem(selectedItem)
    local slot = InventorySlotFinger
    
    local handPos = {['x'] = 65535, ['y'] = slot, ['z'] = 0}
    if player:getInventoryItem(slot) and player:getInventoryItem(slot):getCount() > 5 then
      return 10000
    end

    if item and not player:getInventoryItem(slot) then
      g_game.move(item, handPos, item:getCount())
    end
  end
end

function PvpModule.removeManaShieldRing()
 if g_game.isOnline() then
    local player = g_game.getLocalPlayer()
    local slot = InventorySlotFinger
    
    local bpPos = {['x'] = 65535, ['y'] = 64, ['z'] = 0}
    if player:getInventoryItem(slot) then
      g_game.move(player:getInventoryItem(slot), bpPos, item:getCount())
    end
  end
end

function activeManaShield(player, health, maxHealth, oldHealth)
  if UI.AutoManaShield:isChecked() then
    if player:getHealthPercent() <= UI.HealthBarMin:getValue() then
      PvpModule.equipeManaShieldRing()
    end
    if player:getHealthPercent() >= UI.HealthBarMax:getValue() then

    end
  end
end

function PvpModule.addCreatureToSio(id, name)
  local item = g_ui.createWidget('ListRowComplex', UI.HealList)
  item:setText(name)
  item:setTextAlign(AlignLeft)
  item:setId(#UI.HealList:getChildren()+1)
  item.idCreature = id

  local removeButton = item:getChildById('remove')
  connect(removeButton, {
    onClick = function(button)
      if removePathWindow then return end

      local row = button:getParent()
      local pathName = row:getText()

      local yesCallback = function()
        row:destroy()
        removePathWindow:destroy()
        removePathWindow=nil
      end

      local noCallback = function()
        removePathWindow:destroy()
        removePathWindow=nil
      end

      removePathWindow = displayGeneralBox(tr('Remove'), 
        tr('Remove '..pathName..'?'), {
        { text=tr('Yes'), callback=yesCallback },
        { text=tr('No'), callback=noCallback },
        anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
    end
  })

end

-- Any global module functions here

return PvpModule
