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
    for i,v in ipairs(tableXml.root.panel) do
        if v._attr.name == 'Walker' then
            for x,item in ipairs(v.control.item) do
                item = item._attr.text
                if string.find(item, 'Stand') or string.find(item, 'Node') then
                    item = item:gsub("%(", '')
                    item = item:gsub("%)", '')
                    item = item:gsub("Stand ", '')
                    item = item:gsub("Node ", '')
                    item = item:gsub(" ", '')
                    position = item:explode(',')

                    PathsModule.createPathWithLabel(position, 'node', '')
                else
                    PathsModule.createPathWithLabel(position, item, item)
                end
            end
        end
    end

end

function ScriptModule.loadSupport(tableXml)
    print('not implemented')
end

function ScriptModule.loadScript(file, force)
    BotLogger.debug("ScriptModule.loadScript("..file..")")
    local FILE_NAME = scriptsDir.."/"..file

    local loadFunc = function()
        local tableXml = simpleTreeHandler()

        local f, e = io.open(FILE_NAME, "r")
        if f then
            local xmltext = f:read("*a")
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