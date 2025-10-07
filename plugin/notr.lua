if vim.g.notr_nvim_loaded then
  return
end
vim.g.notr_nvim_loaded = true

local function safe_require(module)
  local ok, mod = pcall(require, module)
  if not ok then
    vim.notify(string.format("notr.nvim: failed to load %s\n%s", module, mod), vim.log.levels.ERROR)
    return nil
  end
  return mod
end

local function trim_or_nil(text)
  if not text then
    return nil
  end
  local trimmed = vim.trim(text)
  if trimmed == "" then
    return nil
  end
  return trimmed
end

vim.api.nvim_create_user_command("NotrNotebooks", function()
  local mod = safe_require("notr")
  if mod then
    mod.pick_notebook()
  end
end, {})

vim.api.nvim_create_user_command("NotrNotes", function(cmd_opts)
  local mod = safe_require("notr")
  if mod then
    mod.pick_notes(cmd_opts.args ~= '' and cmd_opts.args or nil)
  end
end, { nargs = '?' })

vim.api.nvim_create_user_command("NotrSync", function()
  local mod = safe_require("notr")
  if mod then
    mod.sync()
  end
end, {})

vim.api.nvim_create_user_command("NotrNewNotebook", function(cmd_opts)
  local mod = safe_require("notr")
  if not mod then
    return
  end
  local name = trim_or_nil(cmd_opts.args)
  if not name then
    name = trim_or_nil(vim.fn.input("Notebook name: "))
  end
  if not name then
    vim.notify("notr: notebook name required", vim.log.levels.WARN)
    return
  end
  local ok, err = pcall(mod.new_notebook, name)
  if not ok then
    vim.notify(string.format("notr: failed to create notebook: %s", err), vim.log.levels.ERROR)
  end
end, { nargs = '?' })

vim.api.nvim_create_user_command("NotrNewNote", function(cmd_opts)
  local mod = safe_require("notr")
  if not mod then
    return
  end
  local notebook = trim_or_nil(cmd_opts.args)
  if not notebook then
    notebook = trim_or_nil(vim.fn.input("Notebook: "))
  end
  if not notebook then
    vim.notify("notr: notebook name required", vim.log.levels.WARN)
    return
  end
  local ok, err = pcall(mod.new_note, notebook)
  if not ok then
    vim.notify(string.format("notr: failed to start new note: %s", err), vim.log.levels.ERROR)
  end
end, { nargs = '?' })
