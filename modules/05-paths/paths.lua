--[[
  @Authors: Ben Dol (BeniS)
  @Details: Pathing bot module logic and main body.
]]

PathsModule = {}

-- load module events
dofiles('events')

PathsToWalk = {}
local Panel = {}
local UI = {}

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
function PathsModule.getUI() return UI end

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
  table.insert(PathsToWalk, posToWalk)

  PathsModule.addToPathList(posToWalk);
end

function PathsModule.terminate()
  PathsModule.stop()

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
  UI = {
    AutoExplore = panel:recursiveGetChildById('AutoExplore'),
    PathMap = panel:recursiveGetChildById('PathMap'),
    PathList = panel:recursiveGetChildById('PathList')
  }

  -- Load image resources
  UI.Images = {
    g_ui.createWidget("NodeImage", UI.PathMap)
  }
end

function PathsModule.addToPathList(target)
  local item = g_ui.createWidget('ListRowComplex', UI.PathList)
  item:setText(postostring(target))
  item:setTextAlign(AlignLeft)
  item:setId(#UI.PathList:getChildren()+1)
  item.target = target

  local removeButton = item:getChildById('remove')
  connect(removeButton, {
    onClick = function(button)
      if removeTargetWindow then return end

      local row = button:getParent()
      local targetName = row:getText()

      local yesCallback = function()
        row:destroy()
        TargetsModule.removeTarget(targetName)
        removeTargetWindow:destroy()
        removeTargetWindow=nil
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
  for k,_ in pairs(UI) do
    UI[k] = nil
  end

  Panel:destroy()
  Panel = nil
end

function PathsModule.bindHandlers()

end

function PathsModule.online()
  UI.PathMap:load()
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
  if not UI.PathMap:isDragging() then
    UI.PathMap:setCameraPosition(player:getPosition())
    UI.PathMap:setCrossPosition(player:getPosition())
  end
end

function PathsModule.onStopEvent(eventId)
  if eventId == PathsModule.smartPath then
    PathsModule.SmartPath.onStopped()
  end
end

return PathsModule
