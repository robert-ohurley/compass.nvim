local state = require("compass.state")
local picker = require("compass.picker")

local M = {}

local config = nil

function M.setup(user_config)
  config = user_config
end

local ignore_next_switch = false

function M.set_ignore_next_switch(value)
  ignore_next_switch = value
end

function M.should_ignore_next_switch()
  return ignore_next_switch
end

local function is_buf_valid(buf)
  return buf ~= nil and vim.api.nvim_buf_is_valid(buf)
end

function M.is_buf_valid(buf)
  return is_buf_valid(buf)
end

local function should_track_buffer(buf)
  if not is_buf_valid(buf) then
    return false
  end

  local buf_type = vim.api.nvim_buf_get_option(buf, "buftype")
  local buf_name = vim.api.nvim_buf_get_name(buf)

  -- Ignore certain buffer types (help, quickfix, terminal, etc.)
  if buf_type ~= "" and buf_type ~= "acwrite" then
    return false
  end

  -- Temporary buffers typically don't have names
  if buf_name == "" then
    return false
  end

  return true
end

function M.should_track_buffer(buf)
  return should_track_buffer(buf)
end

function M.navigate_to(new_buf)
  if ignore_next_switch then
    ignore_next_switch = false
    return
  end

  if not should_track_buffer(new_buf) then
    return
  end

  local root = state.get_root()
  
  -- If root doesn't exist, create it with this buffer
  if root == nil then
    local node = state.create_node(new_buf, nil)
    state.register_node(node)
    state.set_root(node)
    state.set_current(node)
    return
  end

  local cur = state.get_current()

  if cur.buf == new_buf then
    return
  end

  -- In linear mode, prune forward history
  if config.history.mode == "linear" then
    cur.children = {}
  end

  -- Create new node
  local node = state.create_node(new_buf, cur)
  table.insert(cur.children, node)
  state.register_node(node)
  state.set_current(node)
end

function M.back()
  local cur = state.get_current()
  if cur == nil then
    print("Compass: No Previous Navigation Available")
    return
  end

  local parent = cur.parent

  if parent == nil then
    print("Compass: No Previous Navigation Available")
    return
  end

  state.set_current(parent)
  
  -- Navigate to parent buffer (if cur != root)
  if parent.buf ~= nil then
    if not is_buf_valid(parent.buf) then
      print("Compass: No Previous Navigation Available")
      return
    end
    M.set_ignore_next_switch(true)
    vim.api.nvim_set_current_buf(parent.buf)
  end
end

function M.forward()
  local cur = state.get_current()
  if cur == nil then
    print("Compass: No forward history")
    return
  end

  local children = cur.children

  if #children == 0 then
    print("Compass: No forward history")
    return
  end

  if #children == 1 then
    local target = children[1]
    if not is_buf_valid(target.buf) then
      print("Compass: Cannot navigate forward")
      return
    end
    state.set_current(target)
    M.set_ignore_next_switch(true)
    vim.api.nvim_set_current_buf(target.buf)
    return
  end

  picker.choose_forward(children)
end

function M.reset()
  state.reset()
  print("Compass: History reset")
end

function M.toggle_history_mode()
  local root = state.get_root()
  if root == nil then
    print("Compass: No history to toggle (no valid buffers tracked yet)")
    return
  end

  if config.history.mode == "graph" then
    M._convert_graph_to_linear()
  else
    M._convert_linear_to_graph()
  end
end

-- Helper function to get path from current node to root
function M.get_path_to_root()
  local path = {}
  local node = state.get_current()
  if node == nil then
    return path
  end

  while node do
    table.insert(path, node)
    node = node.parent
  end

  return path
end

function M._convert_graph_to_linear()
  local path = M.get_path_to_root()
  if #path == 0 then
    return
  end
  
  -- Prune all branches: for each parent in the path, keep only its child that's in the path
  for i = #path, 2, -1 do
    local parent = path[i]
    local child = path[i - 1]
    
    parent.children = { child }
  end
  
  -- Clear children of current node
  if #path > 0 then
    path[1].children = {}
  end
  
  config.history.mode = "linear"
  print("Compass: Switched to linear mode (pruned branches)")
end

function M._convert_linear_to_graph()
  config.history.mode = "graph"
  print("Compass: Switched to graph mode (preserving branches)")
end

return M
