local state = require("compass.state")

local M = {}

local config = nil

function M.setup(user_config)
  config = user_config
end

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

  -- Build items for chooser
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

  local chooser_type = config.ui.chooser or "ui.select"

  if chooser_type == "telescope" then
    M._choose_with_telescope(items)
  else
    M._choose_with_ui_select(items)
  end
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

function M._choose_with_telescope(items)
  local has_telescope, telescope = pcall(require, "telescope.builtin")
  if not has_telescope then
    print("Compass: Telescope not available, falling back to ui.select")
    M._choose_with_ui_select(items)
    return
  end

  -- Convert items to a format Telescope can use
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local opts = {
    prompt_title = "Compass: Choose forward path",
    finder = finders.new_table({
      results = items,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.text,
          ordinal = entry.text,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.value then
          local node = selection.value.node
          -- Lazy require to avoid circular dependency
          local navigation = require("compass.navigation")
          -- Check if buffer is still valid
          if not navigation.is_buf_valid(node.buf) then
            print(string.format("Compass: Cannot navigate - buffer %d has been deleted", node.buf))
            return
          end
          state.set_current(node)
          navigation.set_ignore_next_switch(true)
          vim.api.nvim_set_current_buf(node.buf)
        end
      end)
      return true
    end,
  }

  pickers.new(opts):find()
end

return M
