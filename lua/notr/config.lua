local M = {}

M.defaults = {
  cmd = "notr",
  auto_sync = true,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts)
  return M.options
end

return M
