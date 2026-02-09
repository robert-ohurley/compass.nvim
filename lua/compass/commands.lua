local navigation = require("compass.navigation")

local M = {}

function M.setup()
  vim.api.nvim_create_user_command("CompassBack", function()
    navigation.back()
  end, { desc = "Navigate back in buffer history", force = true })

  vim.api.nvim_create_user_command("CompassForward", function()
    navigation.forward()
  end, { desc = "Navigate forward in buffer history", force = true })

  vim.api.nvim_create_user_command("CompassChooseForward", function()
    navigation.choose_forward()
  end, { desc = "Choose forward path when ambiguous", force = true })

  vim.api.nvim_create_user_command("CompassReset", function()
    navigation.reset()
  end, { desc = "Reset navigation history", force = true })

  vim.api.nvim_create_user_command("CompassDebugDump", function()
    M.debug_dump()
  end, { desc = "Dump navigation state for debugging", force = true })

  vim.api.nvim_create_user_command("CompassToggleMode", function()
    navigation.toggle_history_mode()
  end, { desc = "Toggle between graph and linear history modes", force = true })
end

function M.debug_dump()
  local state = require("compass.state")
  local nodes = state.get_all_nodes()
  local current = state.get_current()
  local root = state.get_root()

  print("=== Compass Debug Dump ===")
  if root == nil then
    print("No history initialized yet (waiting for first valid buffer)")
    print("==========================")
    return
  end

  if current then
    print(string.format("Current node ID: %d", current.id))
  else
    print("Current node: nil")
  end
  print(string.format("Total nodes: %d", vim.tbl_count(nodes)))
  print("\nNodes:")

  local path = navigation.get_path_to_root()
  local path_nodes = {}
  for _, node in ipairs(path) do
    path_nodes[node.id] = true
  end

  local function echo_colored(text, highlight_group)
    vim.api.nvim_echo({ { text, highlight_group } }, false, {})
  end

  local function print_node(node, indent)
    indent = indent or ""
    local buf_name = ""
    if node.buf then
      if navigation.is_buf_valid(node.buf) then
        buf_name = vim.api.nvim_buf_get_name(node.buf)
        if buf_name == "" then
          buf_name = "[No Name]"
        end
      else
        buf_name = string.format("[DELETED: %d]", node.buf)
      end
    else
      buf_name = "[ROOT]"
    end

    local line = string.format("%sNode %d: %s", indent, node.id, buf_name)
    local is_current = current and node.id == current.id
    local is_in_path = path_nodes[node.id] == true
    
    if is_current then
      -- Current node: green
      echo_colored(line, "DiffAdd")
    elseif is_in_path then
      -- Other nodes in path: yellow
      echo_colored(line, "WarningMsg")
    else
      print(line)
    end
    
    for _, child in ipairs(node.children) do
      print_node(child, indent .. "  ")
    end
  end

  print_node(root)
  print("==========================")
end

return M
