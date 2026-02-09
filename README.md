# compass.nvim

A Neovim plugin for tracking buffer navigation history with support for both graph and linear history modes.

## Features

- **Graph Mode**: Preserves branching navigation history
- **Linear Mode**: Maintains a stack-like navigation history (prunes forward history on branch)
- **Forward Navigation**: Automatically resolves ambiguity or prompts user to choose
- **Visual Debugging**: Color-coded debug dump showing current navigation path

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "robert-ohurley/compass.nvim",
  config = function()
    require("compass").setup({
      history = {
        mode = "graph", -- "graph" | "linear"
      },
    })
  end,
}
```

For local development:

```lua
{
  dir = "/path/to/compass.nvim",
  config = function()
    require("compass").setup({
      history = {
        mode = "graph",
      },
    })
  end,
}
```

## Configuration

```lua
require("compass").setup({
  history = {
    mode = "graph", -- "graph" | "linear"
  },
  debug = false,
})
```

### Example Configuration

```lua
-- Minimal configuration (uses defaults)
require("compass").setup({})

-- With custom settings
require("compass").setup({
  history = {
    mode = "linear", -- Use linear mode instead of graph
  },
  debug = false,
})
```

### Example Keymaps

```lua
vim.keymap.set('n', '<C-u>', '<cmd>CompassBack<CR>', { desc = '[C]ompass [B]ack' })
vim.keymap.set('n', '<C-i>', '<cmd>CompassForward<CR>', { desc = '[C]ompass [F]orward' })
vim.keymap.set('n', '<C-o>', '<cmd>CompassDebugDump<CR>', { desc = '[C]ompass [D]ebug dump' })
```

### Options

#### `history.mode`
- **Type**: `"graph" | "linear"`
- **Default**: `"graph"`
- **Description**: 
  - `"graph"`: Preserves all navigation branches
  - `"linear"`: Prunes forward history when navigating to a new buffer from a previous position

#### `debug`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Enable debug mode (reserved for future use)

## API

### Commands

#### `:CompassBack`
Navigate back in buffer history.

**Behavior**:
- Moves to the previous buffer in the navigation history
- Shows "No Previous Navigation Available" if already at root or buffer is deleted

#### `:CompassForward`
Navigate forward in buffer history.

**Behavior**:
- If there's only one forward path, navigates automatically
- If there are multiple forward paths, opens a selection dialog to choose one
- Shows "No forward history" if there are no forward paths

#### `:CompassChooseForward`
Manually open the forward path selection dialog when navigation is ambiguous.

#### `:CompassReset`
Reset the navigation history.

#### `:CompassToggleMode`
Toggle between graph and linear history modes.

**Behavior**:
- **Graph → Linear**: Prunes all branches, keeping only the linear path from current to root
- **Linear → Graph**: Switches mode (future navigations will preserve branches)

#### `:CompassDebugDump`
Display a debug dump of the navigation state.

**Output**:
- Shows the current node ID
- Displays total number of nodes
- Prints the navigation tree structure
- **Path from current to root is highlighted in green**

### Programmatic API

#### `require("compass").setup(config)`
Initialize the plugin with the given configuration.

#### `require("compass").toggle_history_mode()`
Programmatically toggle between graph and linear modes.

#### `require("compass").get_config()`
Get the current configuration.

## How It Works

- **Nodes represent visits, not buffers**: The same buffer can appear multiple times in the history
- **Root node**: The first valid buffer you open becomes the root node
- **Automatic tracking**: Buffer navigation is automatically detected via `BufEnter` and `BufReadPost` events
- **Filtering**: Only valid file buffers with names are tracked (temporary buffers are ignored)

## Examples

### Linear Navigation
```
A → B → C
back → B
navigate → D
Result: A → B → D (C is discarded)
```

### Graph Navigation
```
A → B → C
back → B
navigate → D
Result:
      C
      |
A → B → D
```

### Forward Ambiguity
When at a node with multiple children, `:CompassForward` or `:CompassChooseForward` will open a selection dialog showing:
- Filename with 2 parent directories (e.g., `project/src/file.rb`)
- Node ID for reference

## Notes

- History is not persisted across sessions
- Buffer validation is performed before navigation (deleted buffers are skipped)
- The plugin only tracks buffers with file names (temporary/unnamed buffers are ignored)
