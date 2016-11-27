--[[
  @Authors: Shaykie
  @Details: Actions methods for PATH.
]]

Action = {}

function Action.doActionForPlayer(function_)
    if type(function_) == 'string' then
        local t = _G
        print(t)
        t.cid = cid
        local f = assert(loadstring(function_))
        setfenv(f, t)
        f(cid)
    elseif type(function_) == 'function' then
        function_(cid)
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

function Action.sellItemForNpc(item, qty)
  g_game.sellItem(item, qty, true)
end

function Action.sellItemForNpc(item, qty, ignoreCap, buyWithBP)
  g_game.buyItem(item, qty, ignoreCap, buyWithBP)
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

--rever isso pq ta mt horrivel
function Action.condition(param1, cond, param2, ifp, elsep)
  if cond == '>' then
    if Action.doActionForPlayer(param1) > param2 then
      Action.doActionForPlayer(ifp)
    else
      Action.doActionForPlayer(elsep)
    end
  elseif cond == '<' then
    if Action.doActionForPlayer(param1) < param2 then
      Action.doActionForPlayer(ifp)
    else
      Action.doActionForPlayer(elsep)
    end
  end
end
