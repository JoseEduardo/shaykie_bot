--[[
  @Authors: Ben Dol (BeniS)
  @Details: 
]]

dofile('loot.lua')

-- required by the event handler
function LootModule.getModuleId()
  return "LootModule"
end

LootModule.dependencies = {
  "BotModule"
}

--[[ Default Options ]]

LootModule.options = {
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
LootModule.init()