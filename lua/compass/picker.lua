local state = require("compass.state")

local M = {}

local function get_buffer_info(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  local name = path
  if path == "" then
    name = "[No Name]"
  else
    -- Extract basename + up to 2 parent directories
    local basename = vim.fn.fnamemodify(path, ":t")
    local parent1 = vim.fn.fnamemodify(path, ":h:t")
    local parent2 = vim.fn.fnamemodify(path, ":h:h:t")
    
    if parent2 ~= "" and parent2 ~= parent1 and parent2 ~= basename then
      name = parent2 .. "/" .. parent1 .. "/" .. basename
    elseif parent1 ~= "" and parent1 ~= basename then
      name = parent1 .. "/" .. basename
    else
      name = basename
    end
  end
  return {
    buf = buf,
    name = name,
    path = path,
  }
end

function M.choose_forward(children)
  if #children == 0 then
    return
  end

  -- Build items for picker
  local items = {}
  for _, node in ipairs(children) do
    local info = get_buffer_info(node.buf)
    table.insert(items, {
      node = node,
      text = info.name,
      path = info.path,
      id = node.id,
    })
  end

  M._choose_with_ui_select(items)
end

function M._choose_with_ui_select(items)
  local options = {}
  for _, item in ipairs(items) do
    table.insert(options, item.text)
  end

  vim.ui.select(options, {
    prompt = "Compass: Choose forward path",
    format_item = function(option)
      -- Find the item by text
      for _, item in ipairs(items) do
        if item.text == option then
          return string.format("%s (id: %d)", item.text, item.id)
        end
      end
      return option
    end,
  }, function(choice, idx)
    if choice and idx then
      local selected_item = items[idx]
      if selected_item then
        -- Lazy require to avoid circular dependency
        local navigation = require("compass.navigation")
        -- Check if buffer is still valid
        if not navigation.is_buf_valid(selected_item.node.buf) then
          print(string.format("Compass: Cannot navigate - buffer %d has been deleted", selected_item.node.buf))
          return
        end
        state.set_current(selected_item.node)
        navigation.set_ignore_next_switch(true)
        vim.api.nvim_set_current_buf(selected_item.node.buf)
      end
    end
  end)
end

return M
