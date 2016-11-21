--[[
  @Authors: Ben Dol (BeniS)
  @Details: Path class for pathing control/logic.
]]
if not CandyConfig then
  dofile("candyconfig.lua")
end

Path = extends(CandyConfig, "Path")

Path.create = function(target, command)
  local path = Path.internalCreate()

  path.nodes = {}
  path.target = target or {}
  path.command = command or ""

  return path
end

-- gets/sets

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

  -- complex nodes

  if self.settings then
    node.settings = {}
    for i,setting in pairs(self.settings) do
      if setting then
        node.settings[i] = setting:toNode()
      end
    end
  end

  return node
end

function Path:parseNode(node)
  CandyConfig.parseNode(self, node)

  -- complex parse
  if node.settings then
    self.settings = {}
    for k,v in pairs(node.settings) do
      local setting = Path.create(self)
      setting:parseNode(v)
      self.settings[tonumber(k)] = setting
    end
  end
end