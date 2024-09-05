
-- Closes the buffer without closing the window.
-- Goes the previous buffer if it exists, otherwise goes to a "random" open buffer.
local function close_buffer()
  local prev_bufnr = vim.fn.bufnr("#")

  if vim.fn.buflisted(prev_bufnr) == 1 then
    vim.cmd(":b#|bd#")
    return
  end

  -- prev buffer doesn't exist, choose some other buffer
  current_bufnr = vim.fn.bufnr("%")
  for i, bufinfo in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if bufinfo.bufnr ~= current_bufnr then
      vim.cmd(":b" .. bufinfo.bufnr .. "|bd#")
      return
    end
  end
end

vim.keymap.set("n", "<leader>bd", close_buffer, { noremap = true, silent = true })

