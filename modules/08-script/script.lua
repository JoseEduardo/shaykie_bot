ScriptModule = {}
ScriptModule.widgets = {}

local UI = {}
local Panel = {
  --
}

-- load module events
dofiles('events')
dofile("LuaXML/xml.lua")
dofile("LuaXML/handler.lua")

-- incremento = 202/286
local map = modules.game_interface.getMapPanel()

function ScriptModule.getPanel() return Panel end
function ScriptModule.setPanel(panel) Panel = panel end
function ScriptModule.getUI() return UI end

local scriptsDir = ShaykieBot.getWriteDir().."/scripts"

function ScriptModule.init()
    local botTabBar = ShaykieBot.window:getChildById('botTabBar')
    local tab = botTabBar:addTab(tr('Scripts'))

    local tabPanel = botTabBar:getTabPanel(tab)
    local tabBuffer = tabPanel:getChildById('tabBuffer')

    Panel = g_ui.loadUI('script.otui', tabBuffer)
    ScriptModule.loadUI(Panel)
    ScriptModule.bindHandlers()

    ScriptModule.refresh()
    refreshEvent = cycleEvent(ScriptModule.refresh, 8000)

    Modules.registerModule(ScriptModule)
end

function ScriptModule.loadUI(panel)
  UI = {
    LoadList = panel:recursiveGetChildById('LoadList'),
    LoadButton = panel:recursiveGetChildById('LoadButton')
  }
end

function ScriptModule.bindHandlers()
  connect(UI.LoadList, {
    onChildFocusChange = function(self, focusedChild, unfocusedChild, reason)
        if reason == ActiveFocusReason then return end
        if focusedChild == nil then 
          UI.LoadButton:setEnabled(false)
          loadListIndex = nil
        else
          UI_Path.LoadButton:setEnabled(true)
          loadListIndex = UI.LoadList:getChildIndex(focusedChild)
        end
      end
    })
end

function ScriptModule.refresh()
  UI.LoadList:destroyChildren()

  local files = g_resources.listDirectoryFiles(scriptsDir)
  for _,file in pairs(files) do
    PathsModule.addFile(file)
  end

end

function ScriptModule.addFile(file)
  local item = g_ui.createWidget('ListRowComplex', UI_Path.LoadList)
  item:setText(file)
  item:setTextAlign(AlignLeft)
  item:setId(file)

  local removeButton = item:getChildById('remove')
  connect(removeButton, {
    onClick = function(button)
      if removeFileWindow then return end

      local row = button:getParent()
      local fileName = row:getText()

      local yesCallback = function()
        g_resources.deleteFile(pathsDir..'/'..fileName)
        row:destroy()

        removeFileWindow:destroy()
        removeFileWindow=nil
      end
      local noCallback = function()
        removeFileWindow:destroy()
        removeFileWindow=nil
      end

      removeFileWindow = displayGeneralBox(tr('Delete'), 
        tr('Delete '..fileName..'?'), {
        { text=tr('Yes'), callback=yesCallback },
        { text=tr('No'), callback=noCallback },
        anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
    end
  })
end

function ScriptModule.online()
    map.onGeometryChange = ScriptModule.updatePosition
    g_ui.loadUI("script")
end

function ScriptModule.offline()
    ScriptModule.clear()
end

function ScriptModule.loadPaths(tableXml)
    --http://www.ufjf.br/lapic/files/2010/06/Tutorial_Lua_XML_Parser.pdf
    local position = {}
    while x <= #tableXml.root.panel do
        if tableXml.root.panel[x]._attr.name == 'Walker' then
            while i <= #tableXml.root.panel[x].control.item do
                local item = tableXml.root.panel[x].control.item[i]._attr.text
                print(item)
                if string.find(item, 'Stand') or string.find(item, 'Node') then
                    position = item:match("%((%a+)%)")
                    position = position:trim()
                    position = position:explode(',')

                    PathsModule.createPathWithLabel(position, 'node', '')
                else
                    PathsModule.createPathWithLabel(position, item, item)
                end
                i = i + 1
            end
            x = #tableXml.root.panel+1
        else
            x = x+1;
        end
    end
end

function ScriptModule.loadSupport(tableXml)
    print('not implemented')
end

function ScriptModule.loadScript(file, force)
    BotLogger.debug("ScriptModule.loadScript("..file..")")
    local path = scriptsDir.."/"..file

    local loadFunc = function()
        local filename = path
        local xmltext = ""
        local f, e = io.open(filename, "r")
        if f then
            xmltext = f:read("*a")
        
            --Instancia o objeto que faz a conversao de XML para uma table lua
            local xmlparser = xmlParser(tableXml)
            xmlparser:parse(xmltext)

            --load paths
            ScriptModule.loadPaths(tableXml)
        else
            BotLogger.debug("ScriptModule.loadScript_ERROR("..e..")")
        end
    end

    if not loadWindow then
      local msg = "Would you like to load "..file.."?"

      local yesCallback = function()
        loadFunc()

        loadWindow:destroy()
        loadWindow=nil
      end

      local noCallback = function()
        loadWindow:destroy()
        loadWindow=nil
      end

      loadWindow = displayGeneralBox(tr('Load Script'), tr(msg), {
        { text=tr('Yes'), callback = yesCallback},
        { text=tr('No'), callback = noCallback},
        anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
    end
end

return ScriptModule