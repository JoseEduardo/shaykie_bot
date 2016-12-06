--[[
  @Authors: Ben Dol (BeniS)
  @Details: 
]]

dofile('hud.lua')

-- required by the event handler
function HudModule.getModuleId()
  return "HudModule"
end

HudModule.dependencies = {
  "BotModule"
}

--[[ Default Options ]]

HudModule.options = {
  --
}

--[[ Register Events ]]

table.merge(HudModule, {
  --
})

HudModule.events = {
  --
}

--[[ Register Listeners ]]

table.merge(HudModule, {
  --
})

HudModule.listeners = {
  --
}

--[[ Functions ]]

function HudModule.stop()
  EventHandler.stopEvents(HudModule.getModuleId())
  ListenerHandler.stopListeners(HudModule.getModuleId())
end

-- Start Module
HudModule.init()