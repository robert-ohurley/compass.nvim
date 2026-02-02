local M = {}

local default_config = {
  history = {
    mode = "graph",
  },
  debug = false,
}

local config = vim.deepcopy(default_config)

function M.setup(user_config)
  user_config = user_config or {}
  config = vim.tbl_deep_extend("force", default_config, user_config)

  local state = require("compass.state")
  local navigation = require("compass.navigation")
  local commands = require("compass.commands")

  navigation.setup(config)
  commands.setup()

  local function should_track_buffer(buf)
    return navigation.should_track_buffer(buf)
  end

  local initialized = false

  local augroup = vim.api.nvim_create_augroup("CompassNavigation", { clear = true })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = augroup,
    callback = function()
      local current_node = state.get_current()
      if current_node and current_node.buf then
        local current_buf = vim.api.nvim_get_current_buf()
        if current_node.buf == current_buf then
          local cursor = vim.api.nvim_win_get_cursor(0)
          current_node.cursor = { line = cursor[1], col = cursor[2] + 1 }
        end
      end
    end,
  })

  -- Use BufEnter for navigation detection
  -- BufReadPost also fires after file is loaded (ensures name is set)
  vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
    group = augroup,
    callback = function()
      -- Check if we should ignore this switch (plugin-internal navigation)
      if navigation.should_ignore_next_switch() then
        navigation.set_ignore_next_switch(false)
        return
      end

      local current_buf = vim.api.nvim_get_current_buf()

      if not should_track_buffer(current_buf) then
        return
      end

      local current_node = state.get_current()

      if not initialized then
        initialized = true
        navigation.navigate_to(current_buf)
        return
      end

      -- Check if this is a navigation event (buffer actually changed)
      if current_node and current_node.buf ~= current_buf then
        navigation.navigate_to(current_buf)
      end
    end,
  })
end

function M.get_config()
  return config
end

function M.toggle_history_mode()
  local navigation = require("compass.navigation")
  navigation.toggle_history_mode()
end

return M
