local config = require("notr.config")
local cli = require("notr.cli")

local M = {}

local state = {}

local function make_heading(title)
  title = title or "(untitled)"
  title = vim.trim(title)
  if title == "" then
    title = "Note"
  end
  return "# " .. title
end

local function build_content(title, body)
  local heading = make_heading(title)
  body = body or ""
  if body ~= "" then
    return heading .. "\n\n" .. body
  else
    return heading .. "\n"
  end
end

local function set_buffer_name(buf, notebook, note_id)
  if note_id then
    vim.api.nvim_buf_set_name(buf, string.format("notr://%s/%s.md", notebook, note_id))
  else
    vim.api.nvim_buf_set_name(buf, string.format("notr://%s/new.md", notebook))
  end
end

local function sync_if_enabled()
  if not config.options.auto_sync then
    return
  end
  vim.notify("notr: syncing...", vim.log.levels.INFO)
  cli.sync_async(function(success, msg)
    vim.schedule(function()
      if success then
        vim.notify("notr: sync complete", vim.log.levels.INFO)
      else
        vim.notify(string.format("notr: sync failed: %s", msg), vim.log.levels.ERROR)
      end
    end)
  end)
end

local function write_note(buf, info, content)
  if info.note_id then
    local ok, err = pcall(cli.update_note, info.notebook, info.note_id, content)
    if not ok then
      vim.notify(string.format("notr: update failed (%s/%s): %s", info.notebook, info.note_id, err), vim.log.levels.ERROR)
      return false
    end
    vim.notify(string.format("notr: saved note %s/%s", info.notebook, info.note_id), vim.log.levels.INFO)
    sync_if_enabled()
    return true
  else
    local ok, note_id_or_err = pcall(cli.create_note, info.notebook, content)
    if not ok then
      vim.notify(string.format("notr: create failed (%s): %s", info.notebook, note_id_or_err), vim.log.levels.ERROR)
      return false
    end
    local note_id = vim.trim(note_id_or_err)
    info.note_id = note_id
    set_buffer_name(buf, info.notebook, note_id)
    vim.notify(string.format("notr: created note %s/%s", info.notebook, note_id), vim.log.levels.INFO)
    sync_if_enabled()
    return true
  end
end

local function on_buf_write(buf)
  local info = state[buf]
  if not info then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")
  if not content:match("\n$") then
    content = content .. "\n"
  end
  local ok = write_note(buf, info, content)
  if ok then
    vim.api.nvim_buf_set_option(buf, "modified", false)
    vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buf })
  end
end

local function setup_autocmds(buf)
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      on_buf_write(buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    callback = function()
      state[buf] = nil
    end,
  })
end

local function open_buffer(opts)
  local notebook = opts.notebook
  local note_id = opts.note_id
  local title = opts.title
  local body = opts.body

  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_option(buf, "buftype", "acwrite")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

  set_buffer_name(buf, notebook, note_id)

  local content = build_content(title, body)
  local lines = vim.split(content, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.api.nvim_set_current_buf(buf)

  state[buf] = {
    notebook = notebook,
    note_id = note_id,
  }

  setup_autocmds(buf)
end

function M.edit_note(opts)
  open_buffer({
    notebook = opts.notebook,
    note_id = opts.note_id,
    title = opts.title,
    body = opts.body,
  })
end

function M.new_note(opts)
  open_buffer({
    notebook = opts.notebook,
    note_id = nil,
    title = opts.title or "New note",
    body = "",
  })
end

return M
