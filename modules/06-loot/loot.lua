--[[
  @Authors: Ben Dol (BeniS)
  @Details: 
]]

LootModule = {}

-- load module events
dofiles('events')

local Panel = {
  --
}

local UI = {}
local lootDir = ShaykieBot.getWriteDir().."/paths"

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

  -- register module
  Modules.registerModule(LootModule)
  LootModule.bindHandlers()
end

function LootModule.loadUI(panel)
  UI = {
    LootActive = panel:recursiveGetChildById('loot'),
    LootList = panel:recursiveGetChildById('LootList'),
    SaveNameEdit = panel:recursiveGetChildById('SaveNameEdit')
  }
end

function LootModule.bindHandlers()
  modules.game_interface.addMenuHook("lootbot", tr("Add to Loot List"), 
    function(menuPosition, lookThing, useThing, creatureThing)
      print('Obter o ID do Item')
    end,
    function(menuPosition, lookThing, useThing, creatureThing)
      return lookThing ~= nil and lookThing:getTile() ~= nil
    end)
end

function LootModule.terminate()
  modules.game_interface.removeMenuHook("lootbot", tr("Add to Loot List"))
  LootModule.stop()

  Panel:destroy()
  Panel = nil
end

function LootModule.checkIDForLoot(idItem)
  local t = UI.LootList:getChildren()
  for idx,child in pairs(t) do
    if child.idItem == idItem then
      return true
    end
  end

  return false
end

function TargetsModule.addNewTarget(name)
  local loot = Loot.create(name, 1, {})

  TargetsModule.addItemToLoot(loot)
  return loot
end

function LootModule.addItemToLoot(loot)
  local item = g_ui.createWidget('ListRowComplex', UI.LootList)
  item:setText(loot:getName())
  item:setTextAlign(AlignLeft)
  item:setId(#UI.LootList:getChildren()+1)
  item.lootItem = loot

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
    local currItem = v.loot
    paths[k] = currItem:toNode()
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
  local item = g_ui.createWidget('ListRowComplex', UI.LootList)
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
        g_resources.deleteFile(pathsDir..'/'..fileName)
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

function LootModule.loadLootList(file, force)
  BotLogger.debug("LootListModule.loadTargets("..file..")")
  local path = lootDir.."/"..file
  local config = g_configs.load(path)
  BotLogger.debug("LootListModule"..tostring(config))
  if config then
    local loadFunc = function()
      PathsModule.clearPathtList()

      local targets = parsePaths(config)
      for v,target in pairs(targets) do
        if target then
          print( target )
          PathsModule.addToPathList(target)
        end
      end
      UI.LootList:focusNextChild()
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


-- Any global module functions here

return LootModule
