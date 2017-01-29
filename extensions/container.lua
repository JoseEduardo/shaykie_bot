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

function Container.getContainerItems(self, ret)
    ret = ret or {}
    for index = self:getSize()-1, 0, -1 do
        local item = self:getItem(index)
        if ItemType(item:getId()):isContainer() then
            ret[#ret+1] = item
            item:getItems(ret)
        else
            ret[#ret+1] = item
        end
    end
    return ret
end

function Container.GetByName(name)
  local items = container:getItems()
  for i = 1, #items do
    if items[i]:getName() == name then
      return items[i]
    end
  end
  return false
end

function Container:UseItem(slot)
  local item = self:getItem(slot) 
  g_game.use(item)
end