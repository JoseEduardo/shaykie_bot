MarketSearchModule = {}
MarketSearchModule.widgets = {}

local currItem = nil
local currID = 0
local startedProc = false
local UI = {}
local Panel = {
  --
}

-- load module events
dofiles('events')

-- incremento = 202/286
local map = modules.game_interface.getMapPanel()

function MarketSearchModule.getPanel() return Panel end
function MarketSearchModule.setPanel(panel) Panel = panel end
function MarketSearchModule.getUI() return UI end

function MarketSearchModule.init()
    Panel = g_ui.loadUI('marketSearch.otui')

    Modules.registerModule(MarketSearchModule)
    initProtocol()
end

function MarketSearchModule.updatePosition(old, new)
    for k,v in pairs(MarketSearchModule.widgets) do
        v:setX(((583 - new.height)*(202/286)) + 200)
    end
end
function MarketSearchModule.online()
    map.onGeometryChange = MarketSearchModule.updatePosition
    g_ui.loadUI("marketSearch")
end

function MarketSearchModule.offline()
    MarketSearchModule.clear()
end

function initProtocol()
  connect(g_game, { onGameStart = registerProtocol,
                    onGameEnd = unregisterProtocol })

  -- reloading module
  if g_game.isOnline() then
    registerProtocol()
  end
end

function registerProtocol()
    ProtocolGame.registerOpcode(GameServerOpcodes.GameServerMarketBrowse, parseMarketBrowse)
end

function unregisterProtocol()
    ProtocolGame.unregisterOpcode(GameServerOpcodes.GameServerMarketBrowse, parseMarketBrowse)
end

local function parseMarketBrowse(protocol, msg)
  local var = msg:getU16()
  local offers = {}

  local buyOfferCount = msg:getU32()
  for i = 1, buyOfferCount do
    table.insert(offers, readMarketOffer(msg, MarketAction.Buy, var))
  end

  local sellOfferCount = msg:getU32()
  for i = 1, sellOfferCount do
    table.insert(offers, readMarketOffer(msg, MarketAction.Sell, var))
  end

  signalcall(onMarketBrowse, offers)
  return true
end

local function onMarketBrowse(offers)
    for i = 1, #offers do
        if checkOffer(offers[i]) then
            break
        end
    end

    local nextID = currID+1;
    MarketSearchModule.procNextItem(nextID)
end

local function checkOffer(offer)
    local price = offer:getPrice()
    local amount = offer:getAmount()
    local timestamp = offer:getTimeStamp()
    local itemName = offer:getItem():getMarketData().name

    if price < currItem.PRICE then
        Market.acceptMarketOffer(amount, MarketAction.Buy, 'Buy')
        --Market.acceptMarketOffer(amount, timestamp, 'Buy')

        print('BUY: '..itemName..', coins: '..price)
        return true
    end
    return false
end

function MarketSearchModule.startProcess()
    startProcess = true
    currID = 0
    MarketSearchModule.procNextItem(currID)
end

function MarketSearchModule.stopProcess()
    startProcess = false
end

function MarketSearchModule.procNextItem(index)
    if startedProc == false then return false end
    if index > countTableItensToBuy()-1 then index = 0 end

    currItem = ItensToBuy[index]
    local browseId = currItem.ID
    MarketProtocol.sendMarketBrowse(browseId)
end

function countTableItensToBuy()
  local count = 0
  for i,v in ipairs(ItensToBuy) do
    count = count+1
  end

  return count
end

return MarketSearchModule