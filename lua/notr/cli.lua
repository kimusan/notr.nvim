local config = require("notr.config")

local M = {}

local function build_cmd(args)
  local cmd = { config.options.cmd }
  vim.list_extend(cmd, args)
  return cmd
end

local function system_run(args, opts)
  opts = opts or {}
  local cmd = build_cmd(args)

  local input = opts.input
  local text = true

  if vim.system then
    local res = vim.system(cmd, { text = text, stdin = input }):wait()
    if res.code ~= 0 then
      local msg = res.stderr
      if not msg or msg == "" then
        msg = res.stdout
      end
      msg = msg or ""
      error(string.format("notr command failed (%d): %s", res.code, vim.trim(msg)))
    end
    return res.stdout
  else
    local output = vim.fn.system(cmd, input)
    local code = vim.v.shell_error
    if code ~= 0 then
      error(string.format("notr command failed (%d): %s", code, vim.trim(output)))
    end
    return output
  end
end

local function run_async(args, callback)
  local cmd = build_cmd(args)
  if vim.system then
    vim.system(cmd, { text = true }, function(res)
      if res.code == 0 then
        callback(true, res.stdout or "")
      else
        local msg = res.stderr
        if not msg or msg == "" then
          msg = res.stdout
        end
        callback(false, vim.trim(msg or ""))
      end
    end)
    return
  end

  local stdout, stderr = {}, {}
  local job = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(stdout, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(stderr, data)
      end
    end,
    on_exit = function(_, code)
      local out = table.concat(stdout, "\n")
      local err = table.concat(stderr, "\n")
      if code == 0 then
        callback(true, out)
      else
        callback(false, (err ~= "") and err or out)
      end
    end,
  })

  if job <= 0 then
    callback(false, "failed to start notr job")
  end
end

local function decode_json(stdout)
  if stdout == nil or stdout == "" then
    return {}
  end
  return vim.json.decode(stdout)
end

function M.list_notebooks()
  local out = system_run({ "export", "--scope", "notebooks", "--format", "json" })
  return decode_json(out)
end

function M.list_notes(notebook)
  local args = { "export", "--scope", "notes", "--format", "json" }
  if notebook and notebook ~= "" then
    table.insert(args, "--notebook")
    table.insert(args, notebook)
  end
  local out = system_run(args)
  return decode_json(out)
end

function M.read_note(notebook, note_id)
  local stdout = system_run({ "view", notebook, tostring(note_id), "--plain" })
  return stdout
end

function M.create_notebook(name)
  local out = system_run({ "notebook", "create", name, "--print-name" })
  return vim.trim(out)
end

function M.create_note(notebook, content)
  local tmp = vim.fn.tempname()
  local lines = vim.split(content, "\n", { plain = true, trimempty = false })
  if #lines == 0 or lines[#lines] ~= "" then
    table.insert(lines, "")
  end
  vim.fn.writefile(lines, tmp)
  local ok, out = pcall(system_run, { "add", notebook, "--file", tmp, "--print-id" })
  os.remove(tmp)
  if not ok then
    error(out)
  end
  return vim.trim(out)
end

function M.update_note(notebook, note_id, content)
  local tmp = vim.fn.tempname()
  local lines = vim.split(content, "\n", { plain = true, trimempty = false })
  if #lines > 0 and lines[#lines] == "" then
    -- preserve trailing newline
  else
    table.insert(lines, "")
  end
  vim.fn.writefile(lines, tmp)
  local ok, err = pcall(system_run, { "update", notebook, tostring(note_id), "--file", tmp })
  os.remove(tmp)
  if not ok then
    error(err)
  end
end

function M.sync()
  local out = system_run({ "sync" })
  return out
end

function M.sync_async(callback)
  run_async({ "sync" }, function(success, msg)
    if callback then
      callback(success, msg)
    end
  end)
end

return M
