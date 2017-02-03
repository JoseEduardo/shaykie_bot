--[[
  @Authors: SHaykie
  @Details: 
]]

LootModule = {}

-- load module events
dofiles('events')

local Panel = {
  --
}

local UI = {}
local lootDir = ShaykieBot.getWriteDir().."/loots"

function LootModule.getPanel() return Panel end
function LootModule.setPanel(panel) Panel = panel end

function LootModule.init()
  -- create tab
  local botTabBar = ShaykieBot.window:getChildById('botTabBar')
  local tab = botTabBar:addTab(tr('Loot'))

  local tabPanel = botTabBar:getTabPanel(tab)
  local tabBuffer = tabPanel:getChildById('tabBuffer')
  Panel = g_ui.loadUI('loot.otui', tabBuffer)

  LootModule.parentUI = ShaykieBot.window
  LootModule.loadUI(Panel)

  -- setup resources
  if not g_resources.directoryExists(lootDir) then
    g_resources.makeDir(lootDir)
  end
  -- register module
  Modules.registerModule(LootModule)
  LootModule.bindHandlers()

  local newItem = g_ui.createWidget('ListRow', UI.LootList)
  newItem:setText("<New Item>")
  newItem:setId("new")

  LootModule.refresh()
  refreshEvent = cycleEvent(LootModule.refresh, 8000)
end

function LootModule.loadUI(panel)
  UI = {
    LootActive = panel:recursiveGetChildById('lootCheckBox'),
    LootList = panel:recursiveGetChildById('LootList'),
    LoadList = panel:recursiveGetChildById('LoadList'),
    LoadButton = panel:recursiveGetChildById('LoadButton'),
    SaveNameEdit = panel:recursiveGetChildById('SaveNameEdit'),
    ItemID = panel:recursiveGetChildById('ItemID'),
    ItemCap = panel:recursiveGetChildById('ItemCap'),
    ItemBp = panel:recursiveGetChildById('ItemBp'),
    ItemLootBox = panel:recursiveGetChildById('ItemLootDisplay')
  }
end

function LootModule.getEnableLoot()
  return UI.LootActive:isChecked();
end

function LootModule.bindHandlers()
  connect(UI.LoadList, {
    onChildFocusChange = function(self, focusedChild, unfocusedChild, reason)
        if reason == ActiveFocusReason then return end
        if focusedChild == nil then 
          UI.LoadButton:setEnabled(false)
          loadListIndex = nil
        else
          UI.LoadButton:setEnabled(true)
          UI.SaveNameEdit:setText(string.gsub(focusedChild:getText(), ".otml", ""))
          loadListIndex = UI.LoadList:getChildIndex(focusedChild)
        end
      end
    })

  connect(UI.LootList, {
    onChildFocusChange = function(self, focusedChild)
      if focusedChild == nil then return end
      selectedTarget = nil
      if focusedChild:getId() ~= "new" then
        selectedTarget = LootModule.getLoot(focusedChild:getText())
        if selectedTarget then
          LootModule.syncLoot(selectedTarget)
        end
      else
        LootModule.syncLoot(nil)
      end
    end
  })

  connect(Container, {
    onOpen = function(container, prevContainer)
      if LootModule.getEnableLoot() ~= true then
        return false
      end

      if not string.find(container:getName(), 'dead') and not string.find(container:getName(), 'slain')  then
        return false
      end

      local freePush = false
      if string.find(container:getName(), 'human') then
        freePush = true
      end
      LootModule.processLoot(container:getItems(), freePush)
      LootModule.processLoot(container:getItems(), freePush)
      LootModule.processLoot(container:getItems(), freePush)
    end
  })

  modules.game_interface.addMenuHook("lootbot", tr("Add to Loot List"), 
    function(menuPosition, lookThing, useThing, creatureThing)
      TargetsModule.addLootItem(useThing:getId(), "", 100, 0)
    end,
    function(menuPosition, lookThing, useThing, creatureThing)
      return useThing ~= nil and useThing:isItem() ~= nil
    end)

  connect(UI.ItemID, {
    onTextChange = function(self, text, oldText)
      --LootModule.setItemPreview(text)
    end
  })
end

function LootModule.processLoot(itemsBP, freePush)
    for k,i in pairs(itemsBP) do
      if freePush then
        local toPos = {x=65535, y=64, z=math.random(0,7)}
        scheduleEvent(function() LootModule.moveItemToBP(i, toPos, i:getCount()) end, math.random(1000, 3000))
      else
        local checkItem = LootProcedure:checkLootList(i:getId())
        if checkItem and checkItem:getBp() ~= '' then
          local backCurr = Container.GetByName(checkItem:getBp())
          if backCurr then
            local toPos = backCurr:getSlotPosition()
            toPos.z = backCurr:getCapacity()-1
            scheduleEvent(function() LootModule.moveItemToBP(i, toPos, i:getCount()) end, math.random(1000, 3000))
          end
        end
      end
    end
end

function LootModule.moveItemToBP(item, toPos, count)
  g_game.move(item, toPos, count)
end

function LootModule.setItemPreview(itemID)
  UI.ItemLootBox:setItemId(itemID)
end

function LootModule.syncLoot(loot)
  if loot == nil then
    UI.ItemID:setText("")
    UI.ItemCap:setText("")
    UI.ItemBp:setText("")
  else
    UI.ItemID:setText(loot:getId())
    UI.ItemCap:setText(loot:getCap())
    UI.ItemBp:setText(loot:getBp())
  end
end

function LootModule.getLoot(name)
  for _,child in pairs(UI.LootList:getChildren()) do

    if child:getId() ~= "new" then
      local t = child.lootItem
      if tostring(t:getName()) == tostring(name) then
        return t
      end
    end
  end
end

function LootModule.terminate()
  modules.game_interface.removeMenuHook("lootbot", tr("Add to Loot List"))
  LootModule.stop()

  if refreshEvent then
    refreshEvent:cancel()
    refreshEvent = nil
  end

  Panel:destroy()
  Panel = nil
end

function LootModule.checkIDForLoot(idItem)
  local t = UI.LootList:getChildren()
  for idx,child in pairs(t) do
    if child:getId() ~= "new" then
      local t = child.lootItem
      if t:getId() == idItem or t:getId() == 'all' then
        return t
      end
    end
  end

  return false
end

function TargetsModule.addLootItem(id, name, cap, bp)
  local loot = Loot.create(id, id, cap, bp)
  LootModule.addItemToLoot(loot)
  return loot
end

function LootModule.addItemToLoot(loot)
  local item = g_ui.createWidget('ListRowComplex', UI.LootList)
  item:setText(loot:getName())
  item:setTextAlign(AlignLeft)
  item:setId(#UI.LootList:getChildren()+1)
  item.lootItem = loot

  local lastIndex = UI.LootList:getChildIndex(item)
  UI.LootList:moveChildToIndex(UI.LootList:getChildById("new"), lastIndex)

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

function writeLootList(config)
  if not config then return end
  local paths = {}

  local t = UI.LootList:getChildren()
  for k,v in pairs(t) do
    if v:getId() ~= "new" then
      local currItem = v.lootItem
      paths[k] = currItem:toNode()
    end
  end

  config:setNode('LootList', paths)
  config:save()

  BotLogger.debug("Saved "..tostring(#paths) .." loot to "..config:getFileName())
end

function LootModule.saveLootList(file)
  local path = lootDir.."/"..file..".otml"
  local config = g_configs.load(path)
  if config then
    local msg = "Are you sure you would like to save over "..file.."?"

    local yesCallback = function()
      writeLootList(config)
      
      saveOverWindow:destroy()
      saveOverWindow=nil

      UI.SaveNameEdit:setText("")
    end

    local noCallback = function()
      saveOverWindow:destroy()
      saveOverWindow=nil
    end

    saveOverWindow = displayGeneralBox(tr('Overwite Save'), tr(msg), {
      { text=tr('Yes'), callback = yesCallback},
      { text=tr('No'), callback = noCallback},
      anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
  else
    config = g_configs.create(path)
    writeLootList(config)

    UI.SaveNameEdit:setText("")
  end

  local formatedFile = file..".otml"
  if not UI.LootList:getChildById(formatedFile) then
    LootModule.addFile(formatedFile)
  end
end

function LootModule.addFile(file)
  local item = g_ui.createWidget('ListRowComplex', UI.LoadList)
  item:setText(file)
  item:setTextAlign(AlignLeft)
  item:setId(file)

  local removeButton = item:getChildById('remove')
  connect(removeButton, {
    onClick = function(button)
      if removeFileWindow then return end

      local row = button:getParent()
      local fileName = row:getText()

      local yesCallback = function()
        g_resources.deleteFile(lootDir..'/'..fileName)
        row:destroy()

        removeFileWindow:destroy()
        removeFileWindow=nil
      end
      local noCallback = function()
        removeFileWindow:destroy()
        removeFileWindow=nil
      end

      removeFileWindow = displayGeneralBox(tr('Delete'), 
        tr('Delete '..fileName..'?'), {
        { text=tr('Yes'), callback=yesCallback },
        { text=tr('No'), callback=noCallback },
        anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
    end
  })
end

function LootModule.clearLootList()
  for k,t in pairs(UI.LootList:getChildren()) do
    if t:getId() ~= "new" then
      UI.LootList:removeChild(t)
    end
  end
end

function parseLoots(config)
  if not config then return end

  local loots = {}

  -- loop each target node
  local index = 1
  for k,v in pairs(config:getNode("LootList")) do
    local loot = Loot.create()
    loot:parseNode(v)
    loots[index] = loot
    index = index + 1
  end

  return loots

end

function LootModule.loadLootList(file, force)
  BotLogger.debug("LootListModule.loadTargets("..file..")")
  local path = lootDir.."/"..file
  local config = g_configs.load(path)
  BotLogger.debug("LootListModule"..tostring(config))
  if config then
    local loadFunc = function()
      LootModule.clearLootList()

      local targets = parseLoots(config)
      for v,target in pairs(targets) do
        if target then
          LootModule.addItemToLoot(target)
        end
      end
      UI.LootList:focusNextChild()
      ShaykieBot.changeOption(UI.LoadList:getId(), file)
    end

    if force then
      loadFunc()
    elseif not loadWindow then
      local msg = "Would you like to load "..file.."?"

      local yesCallback = function()
        loadFunc()

        loadWindow:destroy()
        loadWindow=nil
      end

      local noCallback = function()
        loadWindow:destroy()
        loadWindow=nil
      end

      loadWindow = displayGeneralBox(tr('Load LootList'), tr(msg), {
        { text=tr('Yes'), callback = yesCallback},
        { text=tr('No'), callback = noCallback},
        anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
    end
  end
end

function LootModule.refresh()
  -- refresh the files
  UI.LoadList:destroyChildren()

  local files = g_resources.listDirectoryFiles(lootDir)
  for _,file in pairs(files) do
    LootModule.addFile(file)
  end
end

-- Any global module functions here

return LootModule
