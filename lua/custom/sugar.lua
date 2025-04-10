
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
  vim.keymap.set('v', '<leader>gh', "<cmd>'<,'>DiffviewFileHistory<CR>",
    { desc = 'File history for the current selection' })
  vim.keymap.set('n', '<leader>gc', function()
    -- Open commit for the current line (blame commit) in diffview.
    local file_name = vim.api.nvim_buf_get_name(0)
    local line_number = vim.api.nvim_win_get_cursor(0)[1]
    if line_number == nil or line_number == 0 then
      return
    end

    -- Get the commit hash for the current line
    local commit_hash_cmd = vim.system(
      { 'git', 'blame', '-C', vim.fn.escape(file_name, ' '), '-L', line_number .. ',' .. line_number, '--porcelain' },
      { cwd = git_root }):wait()

    -- The commit hash is the first word of the output
    local commit_hash = vim.fn.split(commit_hash_cmd.stdout, ' ')[1]
    if commit_hash_cmd.code ~= 0 or commit_hash == nil or commit_hash == '' then
      print("Error getting commit hash for line " .. line_number .. " in file " .. file_name)
      print("Err: " .. commit_hash_cmd.stderr .. " " .. commit_hash_cmd.stdout)
      return
    end

    vim.cmd(':DiffviewOpen ' .. commit_hash .. '^...' .. commit_hash)
  end, { desc = 'Show the git blame commit for the current line' })
end

-- Register callback when a buffer is opened. Used to set keymaps that are buffer/env specific.
vim.api.nvim_create_autocmd("BufEnter", {
  callback = on_buffer_load,
})

-- Toggle between dayfox and nightfox themes
local dark_mode = true
local function toggle_theme_dark_mode()
  -- Default dark and light themes
  local dark_theme = "nightfox"
  local light_theme = "dayfox"

  -- Need to update the lualine theme as well, so load up current config (to be modified)
  local lualine_config = require("lualine").get_config()

  dark_mode = not dark_mode
  if dark_mode then
    vim.cmd("colorscheme " .. dark_theme)
    lualine_config.options.theme = dark_theme
  else
    vim.cmd("colorscheme " .. light_theme)
    lualine_config.options.theme = light_theme
  end

  -- Update lualine with the updated config
  require("lualine").setup(lualine_config)
end

vim.keymap.set('n', '<leader>tt', toggle_theme_dark_mode, { desc = 'Toggle theme dark mode' })
