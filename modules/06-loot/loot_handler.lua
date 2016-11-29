--[[
  @Authors: Ben Dol (BeniS)
  @Details: 
]]

dofile('loot.lua')

-- required by the event handler
function LootModule.getModuleId()
  return "LootModule"
end

PvpModule.dependencies = {
  "BotModule"
}

--[[ Default Options ]]

PvpModule.options = {
  --
}

--[[ Register Events ]]

table.merge(LootModule, {
  --
})

LootModule.events = {
  --
}

--[[ Register Listeners ]]

table.merge(LootModule, {
  --
})

LootModule.listeners = {
  --
}

--[[ Functions ]]

function LootModule.stop()
  EventHandler.stopEvents(LootModule.getModuleId())
  ListenerHandler.stopListeners(LootModule.getModuleId())
end

-- Start Module
PvpModule.init()