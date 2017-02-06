--[[
  @Authors: Ben Dol (BeniS)
  @Details: Path class for pathing control/logic.
]]
if not CandyConfig then
  dofile("candyconfig.lua")
end

Path = extends(CandyConfig, "Path")

Path.create = function(target, command, name, label)
  local path = Path.internalCreate()

  path.nodes = {}
  path.target = target or {}
  path.command = command or ""
  path.label = label or "node"
  path.name = name or "new"

  return path
end

-- gets/sets

function Path:getName()
  return self.name
end

function Path:setName(name)
  local oldName = self.name
  if name ~= oldName then
    self.name = name

    signalcall(self.onNameChange, self, name, oldName)
  end
end

function Path:getLabel()
  return self.label
end

function Path:setLabel(label)
  local oldLabel = self.label
  if label ~= oldLabel then
    self.label = label

    signalcall(self.onLabelChange, self, label, oldLabel)
  end
end

function Path:getTarget()
  return self.target
end

function Path:setTarget(target)
  local oldTarget = self.target
  if target ~= oldTarget then
    self.target = target

    signalcall(self.onTargetChange, self, target, oldTarget)
  end
end

function Path:getCommand()
  return self.command
end

function Path:setCommand(command)
  local oldCommand = self.command
  if command ~= oldCommand then
    self.command = command

    signalcall(self.onCommandChange, self, command, oldTarget)
  end
end


function Path:addNode(node)
  if not table.contains(self.nodes, node) then
    node:setPath(self)
    node:setIndex(#self.nodes + 1)
    table.insert(self.nodes, node)
    
    signalcall(self.onAddNode, self, node)
  end
end

function Path:getNodes()
  return self.nodes
end

-- methods

function Path:toNode()
  local node = CandyConfig.toNode(self)

  if self.target then
    setting = self.target
    node.target = setting
  end

  return node
end

function Path:parseNode(node)
  CandyConfig.parseNode(self, node)

  if node.target then
    self.target = node.target
    self.command = node.command
    self.name = node.name
  end

end