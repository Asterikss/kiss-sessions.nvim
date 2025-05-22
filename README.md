# kiss-sessions.nvim

Manage multiple Neovim sessions with a minimal number of associated keymaps and
minimal overhead. (It's quite hacky).

## Problem

The built-in way is not too convenient, to put it lightly.

## Goal

Use as few keymaps / calls associated with the plugin as possible while preserving
all the essential features.

## Description
There are two main actions:

1. LoadSession:
  - Sessions are sorted by the last time of use.
  - Actions:
    - Pick a session to load. (<CR>)
    - Delete a session. (<C-d>)
    - Rename a session. (<C-r>)
  - There is no "LoadLastSession" since this can be achieved by just pressing enter
    in the "LoadSession" window.

2. SaveSession:
  - Sessions are also sorted by the last time of use.
  - Actions:
    - Create a new session. (<CR>)
    - Override an existing session. (<CR>)
    - Delete a session. (<C-d>)
    - Rename a session. (<C-r>)
  - There is deliberately no separation between creating a new session and overriding an existing one.


## Additional Information
- All sessions are always sorted with the most recent one at the top of the list.
  This means that if you want to load the last session, it's always just the keymap
  to open all existing sessions that can be loaded and pressing enter.
- Sessions are not synced automatically. (If, after loading a new session, you open a
  new tab and close Neovim, this will not be reflected in the loaded session).
- Sessions are currently tracked by the specified relative path (you can still make
  it global, but then you would have one set of sessions for all of your projects).
- Requires Telescope.

## Example config
_*assuming lazy_
_*this will lazy load the plugin (recommended)_

```lua
return {
  'asterikss/kiss-sessions.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  keys = {
    {
      '<Leader>n',
      mode = 'n',
      function()
        require('kiss-sessions').LoadSession()
      end,
      desc = 'Load KISS session',
    },
    {
      '<Leader>N',
      mode = 'n',
      function()
        require('kiss-sessions').SaveSession()
      end,
      desc = 'Save KISS session',
    },
    {
      '<A-X>',
      mode = { 'n', 't' },
      function()
        require('kiss-sessions').SaveDefaultSessionAndQuit()
      end,
      desc = 'Save default session and quit',
    },
  },
  cmd = 'LoadDefaultSession',
  opts = {},
}
```
_*you need to call setup (with, for example, opts={})_
