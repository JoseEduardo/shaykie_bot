--[[
  @Authors: Shaykie
  @Details: Extension functions that extend the Contaier class.
]]

function Container:isOpen()
  for _,container in pairs(g_game.getContainers()) do
    if container:getId() == self:getId() then
      return true
    end
  end
  return false
end

function Container.getItems(self, ret)
  ret = ret or {}
  for index = self:getSize()-1, 0, -1 do
    local item = self:getItem(index)
    if item:isContainer() == true then
      ret[#ret+1] = item
      Container.getItems(item, ret)
    else
      ret[#ret+1] = item
    end
  end
  return ret
end

function Container.GetByName(name)
  for _,container in pairs(g_game.getContainers()) do
    if string.lower(container:getName()) == string.lower(name) then
      return container
    end
  end
  return false
end

function Container.getContainerItemByName(name)
  local items = container:getItems()
  for i = 1, #items do
    local idInTibia = Action.getIdByName(name)
    if items[i]:getId() == idInTibia then
      return items[i]
    end
  end
  return false
end

function Container:UseItem(slot)
  local item = self:getItem(slot) 
  g_game.use(item)
end