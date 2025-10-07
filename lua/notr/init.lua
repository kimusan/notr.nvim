local config = require("notr.config")
local cli = require("notr.cli")
local fzf = require("notr.fzf")
local buffer = require("notr.buffer")

local M = {}

config.setup()

function M.setup(opts)
  config.setup(opts)
end

function M.pick_notebook()
  fzf.pick_notebook()
end

function M.pick_notes(notebook)
  fzf.pick_notes(notebook)
end

function M.open_note(notebook, note_id)
  local content = cli.read_note(notebook, note_id)
  local heading, body = content:match("^([^\n]+)\n\n?(.*)$")
  local title = heading and heading:gsub("^#%s*", "") or "(untitled)"
  buffer.edit_note({
    notebook = notebook,
    note_id = note_id,
    title = title,
    body = body,
  })
end

function M.new_note(notebook, title)
  title = title or "New note"
  pcall(cli.create_notebook, notebook)
  buffer.new_note({
    notebook = notebook,
    title = title,
  })
end

function M.new_notebook(name)
  local created = cli.create_notebook(name)
  vim.notify(string.format("notr: ensured notebook '%s'", created), vim.log.levels.INFO)
end

function M.sync()
  cli.sync()
  vim.notify("notr: sync complete", vim.log.levels.INFO)
end

return M
