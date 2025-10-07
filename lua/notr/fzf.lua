local cli = require("notr.cli")
local buffer = require("notr.buffer")

local M = {}

local function ensure_fzf()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    error("notr.nvim requires fzf-lua. Please install it or configure custom pickers.")
  end
  return fzf
end

local function notebook_entry(nb)
  local count = nb.note_count or 0
  return string.format("%s\t%s", nb.name, count)
end

local function note_entry(note)
  return string.format("%s\t%s", tostring(note.note_id or note.id or note.uuid), note.title or "(untitled)")
end

local function preview_note(notebook, note_id)
  local ok, content = pcall(cli.read_note, notebook, note_id)
  if not ok then
    return tostring(content)
  end
  return content
end

local function split_fields(entry)
  if type(entry) == "table" then
    entry = entry[1] or entry.text or entry.line
  end
  if type(entry) ~= "string" then
    return {}
  end
  return vim.split(entry, "\t", { plain = true })
end

function M.pick_notebook()
  local fzf = ensure_fzf()
  local notebooks = cli.list_notebooks()
  local entries = {}
  for _, nb in ipairs(notebooks) do
    table.insert(entries, notebook_entry(nb))
  end
  local opts = {
    prompt = "Notebooks> ",
    delimiter = "\t",
    actions = {
      ["default"] = function(selected)
        local cols = split_fields(selected)
        local notebook = cols[1]
        if notebook and notebook ~= "" then
          M.pick_notes(notebook)
        end
      end,
    },
  }
  opts.previewer = function(item)
      local cols = split_fields(item)
      local notebook = cols[1]
      if not notebook or notebook == "" then
        return ""
      end
      local notes = cli.list_notes(notebook)
      local lines = { string.format("Notes in %s", notebook) }
      for i = 1, math.min(10, #notes) do
        local note = notes[i]
        table.insert(lines, string.format("%s\t%s", note.note_id or note.id, note.title))
      end
      return table.concat(lines, "\n")
  end
  fzf.fzf_exec(entries, opts)
end

function M.pick_notes(notebook)
  local fzf = ensure_fzf()
  if not notebook or notebook == "" then
    M.pick_notebook()
    return
  end
  local notes = cli.list_notes(notebook)
  if #notes == 0 then
    vim.notify(string.format("notr: no notes in %s", notebook), vim.log.levels.INFO)
    return
  end
  local entries = {}
  for _, note in ipairs(notes) do
    note.note_id = note.note_id or note.id or note.uuid
    table.insert(entries, note_entry(note))
  end
  local opts = {
    prompt = string.format("Notes(%s)> ", notebook),
    delimiter = "\t",
    actions = {
      ["default"] = function(selected)
        local cols = split_fields(selected)
        local note_id = cols[1]
        if not note_id or note_id == "" then
          return
        end
        local content = cli.read_note(notebook, note_id)
        local heading, body = content:match("^([^\n]+)\n\n?(.*)$")
        local title = heading and heading:gsub("^#%s*", "") or notebook
        buffer.edit_note({
          notebook = notebook,
          note_id = note_id,
          title = title,
          body = body,
        })
      end,
      ["ctrl-s"] = function(selected)
        local cols = split_fields(selected)
        local note_id = cols[1]
        if note_id and note_id ~= "" then
          cli.sync()
          vim.notify("notr: sync completed", vim.log.levels.INFO)
        end
      end,
    },
  }
  opts.previewer = function(item)
      local cols = split_fields(item)
      local note_id = cols[1]
      if not note_id or note_id == "" then
        return ""
      end
      return preview_note(notebook, note_id)
  end
  fzf.fzf_exec(entries, opts)
end

return M
