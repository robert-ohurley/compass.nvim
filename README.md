  # compass.nvim

A Neovim plugin that tracks your buffer navigation history. It remembers which buffers you visited and where your cursor was in each one, so when you navigate back or forward, you return to the exact position you were at.

You can use it in graph mode (keeps all branches of your navigation) or linear mode (prunes forward history when you branch off). If there are multiple forward paths, it'll ask you which one to take.

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

    vim.keymap.set('n', '<C-j>', '<cmd>CompassBack<CR>', { desc = '[C]ompass [B]ack' })
    vim.keymap.set('n', '<C-k>', '<cmd>CompassForward<CR>', { desc = '[C]ompass [F]orward' })
    vim.keymap.set('n', '<C-l>', '<cmd>CompassDebugDump<CR>', { desc = '[C]ompass [D]ebug dump' })
  end,
}
```


### Options

#### `history.mode`
- **Type**: `"graph" | "linear"`
- **Default**: `"graph"`
- **Description**: 
  - `"graph"`: Preserves all navigation branches
  - `"linear"`: Prunes forward history when navigating to a new buffer from a previous position

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
