--[[
  @Authors: Ben Dol (BeniS)
  @Details: Pathing bot module logic and main body.
]]

PathsModule = {}

-- load module events
dofiles('events')

local Panel = {}
UI_Path = {}

local refreshEvent
local loadListIndex
local NodeTypes = {
  Action = "action",
  Ladder = "ladder",
  Node = "node",
  Pick = "pick",
  Rope = "rope",
  Shovel = "shovel",
  Stand = "stand",
  Walk = "walk"
}

local pathsDir = CandyBot.getWriteDir().."/paths"

function PathsModule.getPanel() return Panel end
function PathsModule.setPanel(panel) Panel = panel end
function PathsModule.getUI() return UI_Path end

function PathsModule.init()
  -- create tab
  local botTabBar = CandyBot.window:getChildById('botTabBar')
  local tab = botTabBar:addTab(tr('Paths'))

  local tabPanel = botTabBar:getTabPanel(tab)
  local tabBuffer = tabPanel:getChildById('tabBuffer')
  Panel = g_ui.loadUI('paths.otui', tabBuffer)

  PathsModule.loadUI(Panel)

  PathsModule.bindHandlers()

  PathsModule.parentUI = CandyBot.window

  -- setup resources
  if not g_resources.directoryExists(pathsDir) then
    g_resources.makeDir(pathsDir)
  end

  g_resources.addSearchPath(g_resources.getRealDir()..g_resources.resolvePath("images"))

  PathsModule.refresh()
  refreshEvent = cycleEvent(PathsModule.refresh, 8000)

  -- register module
  Modules.registerModule(PathsModule)

  connect(g_game, {
    onGameStart = PathsModule.online,
    onGameEnd = PathsModule.offline,
  })

  connect(LocalPlayer, {
    onPositionChange = PathsModule.updateCameraPosition
  })

  if g_game.isOnline() then
    PathsModule.online()
  end

  modules.game_interface.addMenuHook("pathing", tr("Add Path"), 
    function(menuPosition, lookThing, useThing, creatureThing)
      local gameRootPanel = modules.game_interface.getRootPanel()
      local gamemap = gameRootPanel:recursiveGetChildByPos(menuPosition, false)

      if gamemap:getClassName() == 'UIGameMap' then
        PathsModule.createPath(gamemap:getPosition(menuPosition))
      end
    end,
    function(menuPosition, lookThing, useThing, creatureThing)
      return lookThing ~= nil and lookThing:getTile() ~= nil
    end)

  -- event inits
  SmartPath.init()
end

function PathsModule.createPath(posToWalk)
  PathsModule.addToPathList(posToWalk);
end

function PathsModule.terminate()
  PathsModule.stop()

  if refreshEvent then
    refreshEvent:cancel()
    refreshEvent = nil
  end

  if g_game.isOnline() then
    --save here
  end

  modules.game_interface.removeMenuHook("pathing", tr("Add Path"))

  disconnect(g_game, {
    onGameStart = PathsModule.online,
    onGameEnd = PathsModule.offline,
  })

  disconnect(LocalPlayer, {
    onPositionChange = PathsModule.updateCameraPosition
  })

  -- event terminates
  SmartPath.terminate()

  PathsModule.unloadUI()
end

function PathsModule.loadUI(panel)
  UI_Path = {
    AutoExplore = panel:recursiveGetChildById('AutoExplore'),
    PathMap = panel:recursiveGetChildById('PathMap'),
    PathList = panel:recursiveGetChildById('PathList'),
    SaveNameEdit = panel:recursiveGetChildById('SaveNameEdit'),
    LoadList = panel:recursiveGetChildById('LoadList'),
    LoadButton = panel:recursiveGetChildById('LoadButton'),
    Minimap = panel:recursiveGetChildById('PathMap')
  }

  -- Load image resources
  UI_Path.Images = {
    g_ui.createWidget("NodeImage", UI_Path.PathMap)
  }
end

function PathsModule.addToPathList(target)
  local item = g_ui.createWidget('ListRowComplex', UI_Path.PathList)
  item:setText(postostring(target))
  item:setTextAlign(AlignLeft)
  item:setId(#UI_Path.PathList:getChildren()+1)
  item.target = target

  UI_Path.Minimap:addFlag(target, 1, "teste")

  local removeButton = item:getChildById('remove')
  connect(removeButton, {
    onClick = function(button)
      if removeTargetWindow then return end

      local row = button:getParent()
      local targetName = row:getText()

      local yesCallback = function()
        row:destroy()
        removeTargetWindow:destroy()
        removeTargetWindow=nil
        -- trtar aqui para pegar a pos certa e tirar do map
        UI_Path.Minimap:removeFlag(row.target, 1, "")
      end

      local noCallback = function()
        removeTargetWindow:destroy()
        removeTargetWindow=nil
      end

      removeTargetWindow = displayGeneralBox(tr('Remove'), 
        tr('Remove '..targetName..'?'), {
        { text=tr('Yes'), callback=yesCallback },
        { text=tr('No'), callback=noCallback },
        anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
    end
  })

end

function PathsModule.unloadUI()
  for k,_ in pairs(UI_Path) do
    UI_Path[k] = nil
  end

  Panel:destroy()
  Panel = nil
end

function PathsModule.online()
  UI_Path.PathMap:load()
  PathsModule.updateCameraPosition()
end

function PathsModule.offline()
  --save here
end

function PathsModule.updateCameraPosition()
  local player = g_game.getLocalPlayer()
  if not player then return end
  local pos = player:getPosition()
  if not pos then return end
  if not UI_Path.PathMap:isDragging() then
    UI_Path.PathMap:setCameraPosition(player:getPosition())
    UI_Path.PathMap:setCrossPosition(player:getPosition())
  end
end

function PathsModule.onStopEvent(eventId)
  if eventId == PathsModule.smartPath then
    PathsModule.SmartPath.onStopped()
  end
end

function PathsModule.clearPathtList()
  for k,t in pairs(UI_Path.PathList:getChildren()) do
    UI_Path.PathList:removeChild(t)
    UI_Path.Minimap:removeFlag(t, 1, "")
  end
end

function PathsModule.bindHandlers()
  connect(UI_Path.LoadList, {
    onChildFocusChange = function(self, focusedChild, unfocusedChild, reason)
        if reason == ActiveFocusReason then return end
        if focusedChild == nil then 
          UI_Path.LoadButton:setEnabled(false)
          loadListIndex = nil
        else
          UI_Path.LoadButton:setEnabled(true)
          UI_Path.SaveNameEdit:setText(string.gsub(focusedChild:getText(), ".otml", ""))
          loadListIndex = UI_Path.LoadList:getChildIndex(focusedChild)
        end
      end
    })

end

function writePaths(config)
  if not config then return end
  local paths = {}

  local t = UI_Path.PathList:getChildren()
  for k,v in pairs(t) do
    paths[k] = v.target
  end

  config:setNode('Paths', paths)
  config:save()

  BotLogger.debug("Saved "..tostring(#paths) .." paths to "..config:getFileName())
end

function PathsModule.savePaths(file)
  local path = pathsDir.."/"..file..".otml"
  local config = g_configs.load(path)
  if config then
    local msg = "Are you sure you would like to save over "..file.."?"

    local yesCallback = function()
      writePaths(config)
      
      saveOverWindow:destroy()
      saveOverWindow=nil

      UI_Path.SaveNameEdit:setText("")
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
    writePaths(config)

    UI_Path.SaveNameEdit:setText("")
  end

  local formatedFile = file..".otml"
  if not UI_Path.LoadList:getChildById(formatedFile) then
    PathsModule.addFile(formatedFile)
  end
end

function PathsModule.loadPaths(file, force)
  BotLogger.debug("TargetsModule.loadTargets("..file..")")
  local path = pathsDir.."/"..file
  local config = g_configs.load(path)
  BotLogger.debug("TargetsModule"..tostring(config))
  if config then

    local loadFunc = function()
      PathsModule.clearPathtList()

      local targets = parsePaths(config)
      for v,target in pairs(targets) do
        if target then
          PathsModule.addToPathList(target)
        end
      end
      UI_Path.PathList:focusNextChild()

      --if not force then
      --  currentFileLoaded = file
      --  CandyBot.changeOption(UI.LoadList:getId(), file)
      --end

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

      loadWindow = displayGeneralBox(tr('Load Paths'), tr(msg), {
        { text=tr('Yes'), callback = yesCallback},
        { text=tr('No'), callback = noCallback},
        anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
    end
  end
end

function PathsModule.addFile(file)
  local item = g_ui.createWidget('ListRowComplex', UI_Path.LoadList)
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

function PathsModule.refresh()
  -- refresh the files
  UI_Path.LoadList:destroyChildren()

  local files = g_resources.listDirectoryFiles(pathsDir)
  for _,file in pairs(files) do
    PathsModule.addFile(file)
  end
end

function parsePaths(config)
  if not config then return end

  local paths = {}

  -- loop each target node
  local index = 1
  for k,v in pairs(config:getNode("Paths")) do
    PathsModule.addToPathList(v)
    --paths[index] = target
    index = index + 1
  end

  return paths
end

return PathsModule