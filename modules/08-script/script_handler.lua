--[[
  @Authors: Ben Dol (BeniS)
  @Details: 
]]

dofile('script.lua')

-- required by the event handler
function ScriptModule.getModuleId()
  return "ScriptModule"
end

ScriptModule.dependencies = {
  "BotModule"
}

--[[ Default Options ]]

ScriptModule.options = {
  --
}

--[[ Register Events ]]

table.merge(ScriptModule, {
  --
})

ScriptModule.events = {
  --
}

--[[ Register Listeners ]]

table.merge(ScriptModule, {
  --
})

ScriptModule.listeners = {
  --
}

--[[ Functions ]]

function ScriptModule.stop()
  EventHandler.stopEvents(ScriptModule.getModuleId())
  ListenerHandler.stopListeners(ScriptModule.getModuleId())
end

-- Start Module
ScriptModule.init()