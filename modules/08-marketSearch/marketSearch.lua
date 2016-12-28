MarketSearchModule = {}
MarketSearchModule.widgets = {}

local currItem = nil
local currID = 0
MarketSearchModule.startedProc = false
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
  -- create tab
  local botTabBar = ShaykieBot.window:getChildById('botTabBar')
  local tab = botTabBar:addTab(tr('Market'))

  local tabPanel = botTabBar:getTabPanel(tab)
  local tabBuffer = tabPanel:getChildById('tabBuffer')
  Panel = g_ui.loadUI('marketSearch.otui', tabBuffer)

  MarketSearchModule.parentUI = ShaykieBot.window

  Modules.registerModule(MarketSearchModule)
  --initProtocol()
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

function parseMarketBrowse(protocol, msg)
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

function MarketSearchModule.onMarketBrowse(offers)
    for i = 1, #offers do
        if MarketSearchModule.checkOffer(offers[i]) then
            break
        end
    end

    local nextID = currID+1;
    MarketSearchModule.procNextItem(nextID)
end

function MarketSearchModule.checkOffer(offer)
    local price = offer:getPrice()
    local amount = offer:getAmount()
    local timestamp = offer:getTimeStamp()
    local itemName = offer:getItem():getMarketData().name

    if price < currItem.PRICE then
        MarketSearchModule.acceptOffer(amount, MarketAction.Buy, 'Buy')
        --Market.acceptMarketOffer(amount, timestamp, 'Buy')

        print('BUY: '..itemName..', coins: '..price)
        return true
    end
    return false
end

function MarketSearchModule.acceptOffer(amount, timestamp, counter)
  if g_game.getFeature(GamePlayerMarket) then
    local msg = OutputMessage.create()
    msg:addU8(ClientOpcodes.ClientMarketAccept)
    msg:addU32(timestamp)
    msg:addU16(counter)
    msg:addU16(amount)
    send(msg)
  else
    g_logger.error('MarketProtocol.sendMarketAcceptOffer does not support the current protocol.')
  end
end

function MarketSearchModule.startProcess()
    MarketSearchModule.startProcess = true
    MarketSearchModule.procNextItem(0)
end

function MarketSearchModule.stopProcess()
    MarketSearchModule.startProcess = false
end

function MarketSearchModule.procNextItem(index)
    --if MarketSearchModule.startedProc == false then return false end

    if index > countTableItensToBuy()-1 then index = 0 end

    currItem = ItensToBuy[index]
    local browseId = currItem.ID
    MarketSearchModule.sendMarketBrowse(browseId)
end

local function send(msg)
  local protocol = g_game.getProtocolGame()
  if protocol then
    print('M')
    protocol:send(msg)
  end
end

function MarketSearchModule.sendMarketBrowse(browseId)
  if g_game.getFeature(GamePlayerMarket) then
    local msg = OutputMessage.create()
    msg:addU8(ClientOpcodes.ClientMarketBrowse)
    msg:addU16(browseId)
    send(msg)
  else
    g_logger.error('MarketProtocol.sendMarketBrowse does not support the current protocol.')
  end
end

function countTableItensToBuy()
  local count = 0
  for i,v in ipairs(ItensToBuy) do
    count = count+1
  end

  return count
end

return MarketSearchModule