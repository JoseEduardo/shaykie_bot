--[[
  @Authors: Shaykie
  @Details: Extension functions that extend the Contaier class.
]]

Map = {}

function Map.GetTopUseItem(pos)
  g_map.getThing(pos, 2)
end

function Map.IsTileWalkable(pos)
  local tile = g_map.getThing(pos, 0)
  return tile:isWalkable()
end