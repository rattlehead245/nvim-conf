local ps_state = {}
local subproject_cache = {}

---@return table : A list of subprojects in the current working directory.
local function get_subprojects()
  -- Check if we have already cached the subprojects.
  if subproject_cache and #subproject_cache > 0 then
    return subproject_cache
  end

  -- Find all git repos starting from the current working directory.
  local git_repos = vim.fn.systemlist('find . -name .git -prune -exec realpath {} \\;')
  local full_names = {}
  for _, repo in ipairs(git_repos) do
    -- Get the directory name of the git repo.
    local dir_name = vim.fn.fnamemodify(repo, ':h')

    -- Filter out repos that contain `build/` or `install/` in the path.
    if string.find(dir_name, 'build/') or string.find(dir_name, 'install/') then
      goto continue
    end

    -- Get the short name of the directory (name of the project).
    -- If the directory name contains .cpmcache/, go up one level more to get the short name.
    local short_name = vim.fn.fnamemodify(dir_name, ':t')
    if string.find(dir_name, '.cpmcache/') then
      local tmp_dir_name = vim.fn.fnamemodify(dir_name, ':h')
      short_name = vim.fn.fnamemodify(tmp_dir_name, ':t')
    end

    table.insert(full_names, { short_name, dir_name })
    ::continue::
  end

  subproject_cache = full_names
  return subproject_cache
end

---@param project_selection table The project selection from the picker.
---@return integer|nil : The tabpage for the selected project if it exists, otherwise nil.
local function get_tab_for_project_selection(project_selection)
  if not project_selection then
    return nil
  end

  local cached_project = ps_state[project_selection.ordinal]
  if not cached_project then
    return nil
  end

  if not vim.api.nvim_tabpage_is_valid(cached_project.tabpage) then
    return nil
  end

  return cached_project.tabpage
end

---@param opts table : Options for the picker.
local function open_project_picker(opts)
  opts = opts or {}

  local project_list = get_subprojects()

  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  require('telescope.pickers').new(opts, {
    prompt_title = 'Project Switcher',
    finder = require('telescope.finders').new_table {
      results = project_list,
      entry_maker = function(entry)
        return {
          value = entry,
          display = function(display_entry)
            -- Format the display string; i.e. the entries will be shown as:
            -- short_name               full_name
            --
            -- Where short_name is padded to 50 characters.
            local val = display_entry.value
            local combined_name = string.format('%-50s', val[1]) .. val[2]
            return combined_name
          end,
          ordinal = entry[1],
        }
      end,
    },
    sorter = require('telescope.sorters').get_fuzzy_file(),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then
          return
        end

        local tabpage = get_tab_for_project_selection(selection)
        if tabpage then
          vim.api.nvim_set_current_tabpage(tabpage)
          return
        end

        -- Create a new tab and change directory (for the tab) to the selected project.
        vim.api.nvim_command('tabnew')
        tabpage = vim.api.nvim_get_current_tabpage()
        vim.api.nvim_command('tcd ' .. selection.value[2])

        -- Set the tabpage in our state for the selected project.
        ps_state[selection.ordinal] = {
          name = selection.value[1],
          path = selection.value[2],
          tabpage = tabpage,
        }
      end)

      return true
    end,
  }):find()
end

-- Create an autocmd on bufenter to add workspace folder to lsp.
vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('ProjectSwitcher', { clear = true }),
  pattern = '*',
  callback = function()
    local cwd = vim.fn.getcwd()
    local workspace_folders = vim.lsp.buf.list_workspace_folders()

    for _, folder in ipairs(workspace_folders) do
      if folder == cwd then
        -- Already added this folder to the workspace.
        return
      end
    end

    -- Add this project's path as the new workspace folder to the LSP workspace folder list.
    vim.lsp.buf.add_workspace_folder(cwd)
  end,
})

vim.keymap.set('n', '<leader>ps', function()
  open_project_picker({})
end, {
  desc = 'Open project switcher',
})

return {}
