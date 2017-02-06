--[[
  @Authors: Shaykie
  @Details: Actions methods for PATH.
]]

Action = {}

function Action.executeAction(actionFunct)
  if actionFunct ~= '' and actionFunct ~= nil then
    Action.doActionForPlayer(actionFunct)
  end
end

function Action.doActionForPlayer(function_)
    if type(function_) == 'string' then
        local t = _G
        local f = assert(loadstring(function_))
        setfenv(f, t)
        f(t)
    elseif type(function_) == 'function' then
        function_()
    end

    return nil
end

-- ADD BELOW

function Action.talk(message)
  g_game.talk(message)
end

function Action.talkNPC(message)
  g_game.talkPrivate(11, 'NPCs', message)
end

function Action.getCapacity()
  return g_game.getLocalPlayer():getFreeCapacity()
end

function Action.getQtyItem(item)
  local player = g_game.getLocalPlayer()
  return player:getItemsCount(item)
end

function Action.loadPath(file)
  PathsModule.loadPaths(file, true)
end

function Action.getIdByName(name)
  return idsTibia[name]
end

function Action.gotoLabel(label)
  local wayIndex = PathsModule.getWalkPosIndexByLabel(label)
  PathsModule.changeCurrentWaypointIndex(wayIndex)
end

function wait(s)
  local ntime = os.time() + s
  repeat until os.time() > ntime
end