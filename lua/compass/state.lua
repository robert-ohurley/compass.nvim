local M = {}

local State = {
  root = nil,
  current = nil,
  nodes_by_id = {},
  next_id_counter = 0,
}

local Node = {}
Node.__index = Node

function Node.new(buf, parent)
  local self = setmetatable({}, Node)
  self.id = M.next_id()
  self.buf = buf
  self.parent = parent
  self.children = {}
  self.cursor = { line = 1, col = 1 }
  return self
end

function M.next_id()
  State.next_id_counter = State.next_id_counter + 1
  return State.next_id_counter
end

function M.reset()
  State.root = nil
  State.current = nil
  State.nodes_by_id = {}
  State.next_id_counter = 0
end

function M.ensure_root()
  if State.root == nil then
    State.root = Node.new(nil, nil)
    State.current = State.root
    State.nodes_by_id[State.root.id] = State.root
  end
  return State.root
end

function M.get_root()
  return State.root
end

function M.set_root(node)
  State.root = node
end

function M.get_current()
  return State.current
end

function M.set_current(node)
  State.current = node
end

function M.register_node(node)
  State.nodes_by_id[node.id] = node
end

function M.get_node_by_id(id)
  return State.nodes_by_id[id]
end

function M.get_all_nodes()
  return State.nodes_by_id
end

function M.create_node(buf, parent)
  return Node.new(buf, parent)
end

return M
