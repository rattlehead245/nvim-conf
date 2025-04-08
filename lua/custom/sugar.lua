
-- Closes the buffer without closing the window.
-- Goes the previous buffer if it exists, otherwise goes to a "random" open buffer.
local function close_buffer()
  local prev_bufnr = vim.fn.bufnr("#")

  if vim.fn.buflisted(prev_bufnr) == 1 then
    vim.cmd(":b#|bd#")
    return
  end

  -- prev buffer doesn't exist, choose some other buffer
  local current_bufnr = vim.fn.bufnr("%")
  for i, bufinfo in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if bufinfo.bufnr ~= current_bufnr then
      vim.cmd(":b" .. bufinfo.bufnr .. "|bd#")
      return
    end
  end
end

vim.keymap.set("n", "<leader>bd", close_buffer, { noremap = true, silent = true })

-- Yank current buffer file path
vim.keymap.set('n', '<leader>yfp', function()
  local current_file_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p')
  vim.fn.setreg('+', current_file_path)
  vim.print('Yanked ' .. current_file_path .. ' to clipboard')
end, { desc = 'Yank current buffer file path to clipboard' })


-- Set keymaps that are buffer/env specific
local function on_buffer_load(event)
  -- if we're inside a git repo, set keymaps for diff view, etc.
  local current_file = event.file
  if current_file == '' then
    return
  end

  if current_file == nil then
    return
  end

  local file_dir = vim.fn.fnamemodify(current_file, ":h")
  local git_root = vim.fn.systemlist('git -C ' .. vim.fn.escape(file_dir, ' ') .. ' rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 then
    -- Not in a git repo
    return
  end

  -- Diffview
  vim.keymap.set('n', '<leader>gd', '<cmd>DiffviewOpen<CR>', { desc = 'Open diffview' })
  vim.keymap.set('n', '<leader>gm', '<cmd>DiffviewOpen main...HEAD<CR>', { desc = 'Open diffview for main...HEAD' })
  vim.keymap.set('n', '<leader>gh', '<cmd>%DiffviewFileHistory<CR>', { desc = 'File history for the current file' })
  vim.keymap.set('v', '<leader>gh', "<cmd>'<,'>DiffviewFileHistory<CR>", { desc = 'File history for the current selection' })
end

-- Register callback when a buffer is opened. Used to set keymaps that are buffer/env specific.
vim.api.nvim_create_autocmd("BufEnter", {
  callback = on_buffer_load,
})

-- Toggle between dayfox and nightfox themes
local dark_mode = true
local function toggle_theme_dark_mode()
  dark_mode = not dark_mode
  if dark_mode then
    vim.cmd("colorscheme nightfox")
  else
    vim.cmd("colorscheme dayfox")
  end
end

vim.keymap.set('n', '<leader>tt', toggle_theme_dark_mode, { desc = 'Toggle theme dark mode' })
