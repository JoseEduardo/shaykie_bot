--[[
  @Authors: Ben Dol (BeniS)
  @Details: Loot setting class that represents a 
            loot logic setting.
]]
if not CandyConfig then
  dofile("candyconfig.lua")
end

--[[ Loot Class]]

Loot = extends(CandyConfig, "Loot")

Loot.create = function(id, name, cap)
  local loot = Loot.internalCreate()
  
  loot.id = id or 0
  loot.name = name or ""
  loot.cap = cap or 0
  
  return loot
end

-- gets/sets
function Loot:getId()
  return self.id
end

function Loot:setId(id)
  local oldId = self.id
  if id ~= oldId then
    self.id = id

    signalcall(self.onPriorityChange, self, id, oldId)
  end
end

function Loot:getName()
  return self.name
end

function Loot:setName(name)
  local oldName = self.name
  if name ~= oldName then
    self.name = name

    signalcall(self.onNameChange, self, name, oldName)
  end
end

function Loot:getCap()
  return self.cap
end

function Loot:setCap(cap)
  local oldcap = self.cap
  if cap ~= oldcap then
    self.cap = cap
    
    signalcall(self.onSettingsChange, self, cap, oldcap)
  end
end

-- methods

function Loot:toNode()
  local node = CandyConfig.toNode(self)

  -- complex nodes
  return node
end

function Loot:parseNode(node)
  CandyConfig.parseNode(self, node)

  -- complex parse
end