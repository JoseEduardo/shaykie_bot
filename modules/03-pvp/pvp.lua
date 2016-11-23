--[[
  @Authors: Ben Dol (BeniS)
  @Details: 
]]

PvpModule = {}

-- load module events
dofiles('events')

local Panel = {
  --
}

function PvpModule.getPanel() return Panel end
function PvpModule.setPanel(panel) Panel = panel end

function PvpModule.init()
  -- create tab
  local botTabBar = CandyBot.window:getChildById('botTabBar')
  local tab = botTabBar:addTab(tr('PvP'))

  local tabPanel = botTabBar:getTabPanel(tab)
  local tabBuffer = tabPanel:getChildById('tabBuffer')
  Panel = g_ui.loadUI('pvp.otui', tabBuffer)

  PvpModule.parentUI = CandyBot.window

  -- register module
  Modules.registerModule(PvpModule)

  PvpModule.bindHandlers()
end

function PvpModule.bindHandlers()
  g_keyboard.bindKeyPress('Ctrl+E', function()
    local player = g_game.getLocalPlayer()
    local mypos = player:getPosition()
    local tile = g_map.getTile(mypos)
    local bp = player:getInventoryItem(InventorySlotBack)
    local GP = 3031
    local Worm = 3492
    local GPNABP = player:getItem(GP)
    local WormNaBP = player:getItem(Worm)
    local verificaSQM = tile:getTopMoveThing():getId()
    
    if GPNABP ~= nil then
      if verificaSQM ~= GP then
        g_game.move(GPNABP, mypos, 1)
      else
        g_game.move(WormNaBP, mypos, 1)
      end
    end
  end)  

end

function PvpModule.terminate()
  --CreatureList.terminate()
  PvpModule.stop()

  Panel:destroy()
  Panel = nil
end

-- Any global module functions here

return PvpModule
