local M = {}

local default_config = {
  history = {
    mode = "graph", -- "graph" | "linear"
  },
  ui = {
    chooser = "ui.select", -- "ui.select" | "telescope"
  },
  debug = false,
}

local config = vim.deepcopy(default_config)

function M.setup(user_config)
  user_config = user_config or {}
  config = vim.tbl_deep_extend("force", default_config, user_config)

  -- State starts uninitialized - root will be created on first valid buffer
  local state = require("compass.state")

  -- Setup navigation and chooser with config
  local navigation = require("compass.navigation")
  local chooser = require("compass.chooser")
  navigation.setup(config)
  chooser.setup(config)

  -- Setup commands
  local commands = require("compass.commands")
  commands.setup()

  -- Use navigation module's buffer tracking function
  local function should_track_buffer(buf)
    return navigation.should_track_buffer(buf)
  end

  -- Hook into buffer events to detect navigation
  local augroup = vim.api.nvim_create_augroup("CompassNavigation", { clear = true })

  -- Track if we've initialized the first buffer
  local initialized = false

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

      -- Skip if buffer shouldn't be tracked
      if not should_track_buffer(current_buf) then
        return
      end

      local current_node = state.get_current()

      -- If we haven't initialized yet, navigate_to will create root and first node
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
