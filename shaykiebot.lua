--[[
  @Authors: Ben Dol (BeniS)
  @Details: Otclient module entry point. This handles
            main bot controls and functionality.
]]

ShaykieBot = extends(UIWidget, "ShaykieBot")
ShaykieBot.window = nil
ShaykieBot.options = {}
ShaykieBot.defaultOptions = {
  ["LoggerType"] = 1,
  ["PrintLogs"] = false
}

dofile('consts.lua')
dofile('helper.lua')
dofile('logger.lua')
dofile('action.lua')

dofile('modules.lua')
dofile('events.lua')
dofile('listeners.lua')

dofiles('classes')
dofiles('classes/ui')
dofiles('extensions')

local botButton
local botTabBar

local enabled = false
local writeDir = "/shaykiebot"

local function setupDefaultOptions()
  for _, module in pairs(Modules.getOptions()) do
    for k, option in pairs(module) do
      ShaykieBot.defaultOptions[k] = option
    end
  end
end

local function loadModules()
  Modules.init()

  -- setup the default options
  setupDefaultOptions()
end

function init()
  ShaykieBot.window = g_ui.displayUI('shaykiebot.otui')
  ShaykieBot.window:setVisible(false)

  botButton = modules.client_topmenu.addRightGameToggleButton(
    'botButton', 'Bot (Ctrl+Shift+B)', 'shaykiebot', ShaykieBot.toggle)
  botButton:setOn(false)

  botTabBar = ShaykieBot.window:getChildById('botTabBar')
  botTabBar:setContentWidget(ShaykieBot.window:getChildById('botContent'))
  botTabBar:setTabSpacing(-1)

  -- setup resources
  if not g_resources.directoryExists(writeDir) then
    g_resources.makeDir(writeDir)
  end

  -- load modules
  loadModules()

  -- init bot logger
  BotLogger.init()

  -- hook functions
  connect(g_game, { 
    onGameStart = ShaykieBot.online,
    onGameEnd = ShaykieBot.offline
  })

  -- get bot settings
  ShaykieBot.options = g_settings.getNode('Bot') or {}
  
  if g_game.isOnline() then
    ShaykieBot.online()
  end
end

function terminate()
  ShaykieBot.hide()
  disconnect(g_game, {
    onGameStart = ShaykieBot.online,
    onGameEnd = ShaykieBot.offline
  })

  if g_game.isOnline() then
    ShaykieBot.offline()
  end

  Modules.terminate()

  if botButton then
    botButton:destroy()
    botButton = nil
  end

  ShaykieBot.window:destroy()
end

function ShaykieBot.online()
  addEvent(ShaykieBot.loadOptions)

  -- bind keys
  g_keyboard.bindKeyDown('Ctrl+Shift+B', ShaykieBot.toggle)
end

function ShaykieBot.offline()
  Modules.stop()

  ShaykieBot.hide()

  -- unbind keys
  g_keyboard.unbindKeyDown('Ctrl+Shift+B')
end

function ShaykieBot.toggle()
  if ShaykieBot.window:isVisible() then
    ShaykieBot.hide()
  else
    ShaykieBot.show()
    ShaykieBot.window:focus()
  end
end

function ShaykieBot.show()
  if g_game.isOnline() then
    ShaykieBot.window:show()
    botButton:setOn(true)
  end
end

function ShaykieBot.hide()
  ShaykieBot.window:hide()
  botButton:setOn(false)
end

function ShaykieBot.enable(state)
  enabled = state
  if not state then Modules.stop() end
end

function ShaykieBot.isEnabled()
  return enabled
end

function ShaykieBot.getIcon()
  return botIcon
end

function ShaykieBot.getUI()
  return ShaykieBot.window
end

function ShaykieBot.getParent()
  return ShaykieBot.window:getParent() -- main window
end

function ShaykieBot.getWriteDir()
  return writeDir
end

function ShaykieBot.loadOptions()
  local char = g_game.getCharacterName()

  if ShaykieBot.options[char] ~= nil then
    for i, v in pairs(ShaykieBot.options[char]) do
      addEvent(function() ShaykieBot.changeOption(i, v, true) end)
    end
  else
    for i, v in pairs(ShaykieBot.defaultOptions) do
      addEvent(function() ShaykieBot.changeOption(i, v, true) end)
    end
  end
end

function ShaykieBot.changeOption(key, state, loading)
  local loading = loading or false
  if state == nil then
    return
  end
  
  if ShaykieBot.defaultOptions[key] == nil then
    ShaykieBot.options[key] = nil
    return
  end

  if g_game.isOnline() then
    local panel = ShaykieBot.window

    if loading then
      local widget
      for k, p in pairs(Modules.getPanels()) do
        widget = p:recursiveGetChildById(key)
        if widget then break end
      end
      if not widget then 
        widget = panel:recursiveGetChildById(key)
        if not widget then
          BotLogger.warning("ShaykieBot: no widget found with name '"..key.."'")
          return
        end
      end

      local style = widget:getStyle().__class

      if style == 'UITextEdit' then
        widget:setText(state)
      elseif style == 'UIComboBox' then
        widget:setCurrentOption(state)
      elseif style == 'UICheckBox' then
        widget:setChecked(state)
      elseif style == 'UIItem' then
        widget:setItemId(state)
      elseif style == 'UIScrollBar' then
        local value = tonumber(state)
        if value then widget:setValue(value) end
      elseif style == 'UIScrollArea' then
        local child = widget:getChildById(state)
        if child then widget:focusChild(child, MouseFocusReason) end
      end
    end

    Modules.notifyChange(key, state)

    local char = g_game.getCharacterName()

    if ShaykieBot.options[char] == nil then
      ShaykieBot.options[char] = {}
    end

    ShaykieBot.options[char][key] = state
    
    -- Update the settings
    g_settings.setNode('Bot', ShaykieBot.options)
  end
end
