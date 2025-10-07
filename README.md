# notr.nvim

Neovim integration for [Notr](https://github.com/kimusan/notr)—browse, preview, and edit encrypted notes without leaving the editor.

## Features

- Fzf-lua powered pickers for notebooks and notes
- Live Markdown previews driven by `notr view --plain`
- In-buffer editing with automatic `notr update` + optional `notr sync`
- Configurable path to the `notr` executable and auto-sync behaviour

## Requirements

- Neovim 0.8+ (0.10 recommended for `vim.system`)
- [`notr` CLI](https://github.com/kimusan/notr) available on `$PATH`
- [`fzf-lua`](https://github.com/ibhagwan/fzf-lua)

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "kimusan/notr.nvim",
  config = function()
    require("notr").setup({
      cmd = "notr",
      auto_sync = true,
    })
  end,
  dependencies = { "ibhagwan/fzf-lua" },
}
```

## Usage

Commands provided:

- `:NotrNotebooks` – fuzzy pick notebooks, then jump into notes picker.
- `:NotrNotes [notebook]` – open the notes picker directly (optional notebook argument).
- `:NotrNewNotebook [name]` – create (or ensure) a notebook, prompting for a name if omitted.
- `:NotrNewNote [notebook]` – open a new note buffer ready to save into a notebook (prompting if omitted).
- `:NotrSync` – run `notr sync` from inside Neovim.

Within the notes picker:

- `<Enter>` – open the selected note in a markdown buffer backed by `notr update`.
- `Ctrl-s` – trigger a manual `notr sync`.

The opened buffer is marked `acwrite`; `:write` (or auto-write) pushes changes through `notr update` and, if enabled, `notr sync` afterwards.

> **Tip:** run `notr login` in a shell first so the master key is unlocked before you start editing inside Neovim.

## Configuration

Call `require("notr").setup({ ... })` to override defaults:

```lua
require("notr").setup({
  cmd = "notr",      -- path to the notr executable
  auto_sync = true,   -- run `notr sync` after each update
})
```

## Roadmap

- Telescope picker support
- Async status reporting during sync/update operations
- Keymaps for quick note creation

PRs welcome—see [`CONTRIBUTING.md`](../../CONTRIBUTING.md).
