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

function Container.GetByName(name)
  for i, container in pairs(g_game.getContainers()) do
    for j, item in pairs(container:getItems()) do
      if item:getName() == name and item:isContainer() then
        item.container = container
        return item
      end
    end
  end
  return false
end