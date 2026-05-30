vim.g.mapleader = ' '

-- options
vim.opt.backup        = false
vim.opt.writebackup   = false
vim.opt.swapfile      = false
vim.opt.undofile      = false
vim.opt.mouse         = 'a'
vim.opt.clipboard     = 'unnamedplus'
vim.opt.encoding      = 'utf-8'
vim.opt.termguicolors = true
vim.opt.showmode      = false
vim.opt.confirm       = true
vim.opt.scrolloff     = 8
vim.opt.signcolumn    = 'yes'
vim.opt.cursorline    = true

-- editor
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.tabstop        = 2
vim.opt.shiftwidth     = 2
vim.opt.expandtab      = true

-- colorscheme
vim.cmd('colorscheme habamax')

-- highlights
vim.api.nvim_set_hl(0, 'StatusLine',   { bg = '#1e1e2e', fg = '#cdd6f4' })
vim.api.nvim_set_hl(0, 'StatusLineNC', { bg = '#181825', fg = '#585b70' })
vim.api.nvim_set_hl(0, 'CursorLine',   { bg = '#2a2a3d' })
vim.api.nvim_set_hl(0, 'LineNr',       { fg = '#585b70' })
vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#cba6f7', bold = true })

-- statusline
local modes = {
  n      = 'NORMAL',  i = 'INSERT',
  v      = 'VISUAL',  V = 'V-LINE',
  ['\22'] = 'V-BLOCK', c = 'COMMAND',
  R      = 'REPLACE',
}

local mode_colors = {
  n      = '#89b4fa', i = '#a6e3a1',
  v      = '#cba6f7', V = '#cba6f7',
  ['\22'] = '#cba6f7', c = '#f38ba8',
  R      = '#fab387',
}

function _G.statusline()
  local mode     = vim.fn.mode()
  local name     = modes[mode] or mode
  local file     = vim.fn.expand('%:t')
  local modified = vim.bo.modified and ' ●' or ''
  local line     = vim.fn.line('.')
  local col      = vim.fn.col('.')
  local total    = vim.fn.line('$')
  return string.format('  %s  %s%s  %d/%d:%d  ', name, file, modified, line, total, col)
end

vim.opt.statusline = '%!v:lua.statusline()'

-- on open: go to last line
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    if vim.fn.argc() > 0 then
      vim.cmd('normal! G$')
      vim.cmd('startinsert')
    end
  end,
})

-- keymaps
vim.keymap.set('v', '<BS>',  'd',            { desc = 'Delete selection' })
vim.keymap.set('n', '<C-a>', 'ggVG',         { desc = 'Select all' })
vim.keymap.set('i', '<C-a>', '<Esc>ggVG',    { desc = 'Select all' })
vim.keymap.set('n', '<C-s>', ':w<CR>',       { desc = 'Save' })
vim.keymap.set('i', '<C-s>', '<Esc>:w<CR>',  { desc = 'Save' })
vim.keymap.set('n', '<C-z>', 'u',            { desc = 'Undo' })
vim.keymap.set('i', '<C-z>', '<Esc>ui',      { desc = 'Undo' })
vim.keymap.set('n', '<C-k>', 'dd',           { desc = 'Delete line' })
vim.keymap.set('i', '<C-k>', '<Esc>ddi',     { desc = 'Delete line' })
vim.keymap.set('n', '<C-x>', ':q<CR>',       { desc = 'Close buffer' })
vim.keymap.set('i', '<C-x>', '<Esc>:q<CR>',  { desc = 'Close buffer' })
vim.keymap.set('n', '<C-d>', 'ggdG',         { desc = 'Delete all' })
vim.keymap.set('i', '<C-d>', '<Esc>ggdG',    { desc = 'Delete all' })

-- git push
local function git_push()
  vim.cmd('w')

  -- repo root
  local handle    = io.popen('git -C ' .. vim.fn.expand('%:p:h') .. ' rev-parse --show-toplevel 2>/dev/null')
  local repo_root = handle:read('*l')
  handle:close()

  if not repo_root then return end

  -- changed files
  local files_handle = io.popen(
    'git -C ' .. repo_root .. ' diff --name-only && ' ..
    'git -C ' .. repo_root .. ' ls-files --others --exclude-standard'
  )

  -- folder names
  local folders = {}
  local seen    = {}
  for line in files_handle:lines() do
    local folder = line:match('^%.config/([^/]+)') or line:match('^([^/]+)/')
    if folder and not seen[folder] then
      seen[folder] = true
      table.insert(folders, folder)
    end
  end
  files_handle:close()

  -- commit
  local commit_msg = #folders > 0 and 'update ' .. table.concat(folders, ', ') or 'update'
  local prev_win   = vim.api.nvim_get_current_win()
  local buf        = vim.api.nvim_create_buf(false, true)

  vim.cmd('botright 8split')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  vim.fn.termopen(
    'git -C ' .. repo_root .. ' add . && ' ..
    'git -C ' .. repo_root .. ' commit -m "' .. commit_msg .. '" && ' ..
    'git -C ' .. repo_root .. ' push',
    {
      on_exit = function()
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(win)      then vim.api.nvim_win_close(win, true)         end
          if vim.api.nvim_win_is_valid(prev_win) then vim.api.nvim_set_current_win(prev_win)    end
        end)
      end,
    }
  )

  vim.api.nvim_set_current_win(prev_win)
end

vim.keymap.set('n', '<C-j>', git_push, { desc = 'Git add, commit, push' })
vim.keymap.set('i', '<C-j>', function()
  vim.cmd('stopinsert')
  git_push()
end, { desc = 'Git add, commit, push' })

