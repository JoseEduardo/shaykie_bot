--[[
  @Authors: Ben Dol (BeniS)
  @Details: Pathing bot module logic and main body.
]]

PathsModule = {}

-- load module events
dofiles('events')

local Panel = {}
UI_Path = {}

local currIndexWaypoint = 0;
local lastPosWalk = nil

local currentIndexPath
local selectedPath
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

local pathsDir = ShaykieBot.getWriteDir().."/paths"

function PathsModule.getPanel() return Panel end
function PathsModule.setPanel(panel) Panel = panel end
function PathsModule.getUI() return UI_Path end

function PathsModule.init()
  -- create tab
  local botTabBar = ShaykieBot.window:getChildById('botTabBar')
  local tab = botTabBar:addTab(tr('Paths'))

  local tabPanel = botTabBar:getTabPanel(tab)
  local tabBuffer = tabPanel:getChildById('tabBuffer')
  Panel = g_ui.loadUI('paths.otui', tabBuffer)

  PathsModule.loadUI(Panel)

  PathsModule.bindHandlers()

  PathsModule.parentUI = ShaykieBot.window

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

function PathsModule.createPathComplete(posToWalk, label, command)
  local path = Path.create()
  path:setTarget(posToWalk)
  path:setCommand(command)
  path:setLabel(label)
  path:setName(os.clock())

  PathsModule.addToPathList(path);
end

function PathsModule.createPath(posToWalk)
  local path = Path.create()
  path:setTarget(posToWalk)
  path:setCommand("")
  path:setLabel('node')
  path:setName(os.clock())

  PathsModule.addToPathList(path);
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
    Minimap = panel:recursiveGetChildById('PathMap'),
    TextAction = panel:recursiveGetChildById('actionText'),
    TextLabel = panel:recursiveGetChildById('LabelDesc'),
    Waypoint = panel:recursiveGetChildById('StartWayPoint')
  }

  -- Load image resources
  UI_Path.Images = {
    g_ui.createWidget("NodeImage", UI_Path.PathMap)
  }
end

function PathsModule.addMark(pathPos)
  UI_Path.Minimap:removeFlag(pathPos, 1, "teste")
  UI_Path.Minimap:addFlag(pathPos, 2, "GO")
end

function PathsModule.removeMark(pathPos)
  UI_Path.Minimap:removeFlag(pathPos, 2, "GO")
  UI_Path.Minimap:addFlag(pathPos, 1, "teste")
end

function PathsModule.addToPathList(pathTarget)
  local pathPos = pathTarget:getTarget()

  local item = g_ui.createWidget('ListRowComplex', UI_Path.PathList)
  item:setText(postostring(pathPos))
  item:setTextAlign(AlignLeft)
  item:setId(#UI_Path.PathList:getChildren()+1)
  item.path = pathTarget
  item.id = pathTarget:getName()

  UI_Path.Minimap:addFlag(pathPos, 1, "teste")

  local removeButton = item:getChildById('remove')
  connect(removeButton, {
    onClick = function(button)
      if removePathWindow then return end

      local row = button:getParent()
      local pathName = row:getText()

      local yesCallback = function()
        UI_Path.Minimap:removeFlag(row.path.target, 1, "")

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

  if UI_Path.Waypoint:isChecked() then
    if (pos.x == lastPosWalk.x and pos.y == lastPosWalk.y and pos.z == lastPosWalk.z)
     or lastPosWalk == nil then
      currIndexWaypoint = currIndexWaypoint+1
      scheduleEvent(function() PathsModule.processNextWaypoint() end, 1000)
    end
  end
end

function PathsModule.countTablePath()
  local count = 0
  local t = UI_Path.PathList:getChildren()

  for i,v in ipairs(t) do
    count = count+1
  end

  return count
end


function PathsModule.getWalkPosByIndex(pos)
  local index = 0;
  local returnItem = nil;
  local t = UI_Path.PathList:getChildren()

  for i,v in ipairs(t) do
    if index == pos then
      returnItem = v.path
      break
    end
    index = index+1;
  end
  
  return returnItem
end

function PathsModule.getWalkPosByLabel(label)
  local returnItem = nil;
  local t = UI_Path.PathList:getChildren()

  for i,v in ipairs(t) do
    local ptmp = v.path
    if ptmp.label == label then
      returnItem = v.path
      break
    end
  end
  
  return returnItem
end

function PathsModule.getWalkPosIndexByLabel(label)
  local index = 0;
  local t = UI_Path.PathList:getChildren()

  for i,v in ipairs(t) do
    local ptmp = v.path
    if ptmp.label == label then
      break
    end
    index = index+1;
  end
  
  return index
end

function PathsModule.changeCurrentWaypointIndex(index)
  currIndexWaypoint = index
end

function PathsModule.processNextWaypoint()
  local countWP = PathsModule.countTablePath()
  if countWP <= 0 then
    return false
  end

  local player = g_game.getLocalPlayer()
  if currIndexWaypoint > countWP-1 then
    currIndexWaypoint = 0
  end

  local currPath = PathsModule.getWalkPosByIndex(currIndexWaypoint)
  local posWalk  = currPath.target

  if lastPosWalk ~= nil then
    PathsModule.removeMark(lastPosWalk)
  end

  if player:getPosition().z == posWalk.z then
    player:stopAutoWalk()
    PathsModule.addMark(posWalk)
    if currPath.command ~= '' then
      Action.executeAction(currPath.command)
      currIndexWaypoint = currIndexWaypoint+1
      lastPosWalk = posWalk
      PathsModule.processNextWaypoint()
    else
      if player:autoWalk( posWalk ) then
        BotLogger.debug("Success walk: "..currPath.label.." - ".. postostring(posWalk) )
        lastPosWalk = posWalk
      end
    end
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


  connect(UI_Path.PathList, {
      onChildFocusChange = function(self, focusedChild)
       if focusedChild == nil then return end
       selectedPath = focusedChild.path
       if selectedPath then
        PathsModule.setCurrentPath(selectedPath)
        selectedPath = PathsModule.getPaths(focusedChild.id)
       end
     end
  })

 connect(UI_Path.TextAction, {
    onTextChange = function(self, text, oldText)
      if selectedPath then
        selectedPath:setCommand(text)
      end
    end
  })

 connect(UI_Path.TextLabel, {
    onTextChange = function(self, text, oldText)
      if selectedPath then
        selectedPath:setLabel(text)
      end
    end
  })

end

function PathsModule.setCurrentPath(pathSelected)
  UI_Path.TextAction:setText(pathSelected:getCommand(), true)
  UI_Path.TextLabel:setText(pathSelected:getLabel(), true)
end

function PathsModule.getPaths(name)
  local t = UI_Path.PathList:getChildren()
  for idx,child in pairs(t) do
    local t = child.path
    if t and t:getName() == name then
      currentIndexPath = idx
     return t
    end
  end
end


function writePaths(config)
  if not config then return end
  local paths = {}

  local t = UI_Path.PathList:getChildren()
  for k,v in pairs(t) do
    local currPath = v.path
    paths[k] = currPath:toNode()
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
  BotLogger.debug("PathsModule.loadTargets("..file..")")
  local path = pathsDir.."/"..file
  local config = g_configs.load(path)
  BotLogger.debug("PathsModule"..tostring(config))
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

      ShaykieBot.changeOption(UI_Path.LoadList:getId(), file)
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
    local path = Path.create()
    path:parseNode(v)
    paths[index] = path
    index = index + 1
  end

  return paths

end

return PathsModule
