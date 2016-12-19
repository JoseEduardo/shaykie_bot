--[[
  @Authors: Ben Dol (BeniS)
  @Details: 
]]

dofile('marketSearch.lua')

-- required by the event handler
function MarketSearchModule.getModuleId()
  return "MarketSearchModule"
end

MarketSearchModule.dependencies = {
  "BotModule"
}

--[[ Default Options ]]

MarketSearchModule.options = {
  --
}

--[[ Register Events ]]

table.merge(MarketSearchModule, {
  --
})

MarketSearchModule.events = {
  --
}

--[[ Register Listeners ]]

table.merge(MarketSearchModule, {
  --
})

MarketSearchModule.listeners = {
  --
}

--[[ Functions ]]

function MarketSearchModule.stop()
  EventHandler.stopEvents(MarketSearchModule.getModuleId())
  ListenerHandler.stopListeners(MarketSearchModule.getModuleId())
end

-- Start Module
MarketSearchModule.init()