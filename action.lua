--[[
  @Authors: Shaykie
  @Details: Actions methods for PATH.
]]

Action = {}

function Action.doActionForPlayer(cid, function_)
    if type(function_) == 'string' then
        local t = _G
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

function Action.talk(cid, string)
  g_game.talk(string)
end

function Action.sellItemForNpc(cid, item, qty)
  g_game.sellItem(item, qty, true)
end

function Action.sellItemForNpc(cid, item, qty, ignoreCap, buyWithBP)
  g_game.buyItem(item, qty, ignoreCap, buyWithBP)
end

function Action.getCapacity(cid)
  return g_game.getLocalPlayer():getFreeCapacity()
end

--rever isso pq ta mt horrivel
function Action.condition(cid, param1, cond, param2, ifp, elsep)
  if cond == '>' then
    if Action.doActionForPlayer(cid, param1) > param2 then
      Action.doActionForPlayer(cid, ifp)
    else
      Action.doActionForPlayer(cid, elsep)
    end
  elseif cond == '<' then
    if Action.doActionForPlayer(cid, param1) < param2 then
      Action.doActionForPlayer(cid, ifp)
    else
      Action.doActionForPlayer(cid, elsep)
    end
  end
end