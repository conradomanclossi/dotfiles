-- Bootstrap vim-plug if missing
local data_dir = vim.fn.stdpath('data') .. '/site'
if vim.fn.empty(vim.fn.glob(data_dir .. '/autoload/plug.vim')) > 0 then
  vim.fn.system({
    'sh', '-c',
    'curl -fLo ' .. data_dir .. '/autoload/plug.vim --create-dirs ' ..
    'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  })
  vim.cmd [[autocmd VimEnter * PlugInstall --sync | source $MYVIMRC]]
end

-- vim-plug plugin manager
vim.cmd [[
call plug#begin('~/.vim/plugged')

Plug 'mattn/webapi-vim'

" Theme
Plug 'webhooked/kanso.nvim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'edkolev/tmuxline.vim'

" ALE (Asynchronous Lint Engine)
Plug 'dense-analysis/ale'

" Conform formatter
Plug 'stevearc/conform.nvim'

" NERDTree (File Explorer)
Plug 'scrooloose/nerdtree'

" Rust support
Plug 'rust-lang/rust.vim'

" Copilot and related plugins
Plug 'github/copilot.vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'CopilotC-Nvim/CopilotChat.nvim'

" fzf
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Telescope
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.8' }
Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }

" Floaterm
Plug 'voldikss/vim-floaterm'

" Nvim-cmp and related plugins
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'

" Vsnip
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'

call plug#end()
]]


-- Set <space> as leader keymap
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- General settings
vim.o.number = true
vim.o.backspace = 'indent,eol,start'
vim.o.termguicolors = true
vim.cmd.colorscheme('kanso-mist')
vim.o.background = 'dark'

-- Syntax and filetype plugins
vim.cmd [[
syntax enable
filetype plugin indent on
]]

-- Airline config
vim.g.airline_powerline_fonts = 1
vim.g.airline_theme = 'minimalist'
vim.g.airline_section_y = 'BN: %{bufnr("%")}'
vim.o.guifont = "JetBrainsMono Nerd Font"
vim.g['airline#extensions#tabline#enabled'] = 1
vim.g['airline#extensions#tabline#formatter'] = 'default'

-- NERDTree arrows
vim.g.NERDTreeDirArrowExpandable = '▸'
vim.g.NERDTreeDirArrowCollapsible = '▾'

-- ALE linters/fixers for Rust
vim.g.ale_linters = { rust = { 'analyzer' } }
vim.g.ale_fixers = { rust = { 'rustfmt' } }

-- Conform setup
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    -- Conform will run multiple formatters sequentially
    python = { "isort", "black" },
    -- You can customize some of the format options for the filetype (:help conform.format)
    rust = { "rustfmt", lsp_format = "fallback" },
    -- Conform will run the first available formatter
    javascript = { "prettierd", "prettier", stop_after_first = true },
  },
})

vim.api.nvim_create_user_command("Format", function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ["end"] = { args.line2, end_line:len() },
    }
  end
  require("conform").format({ async = true, lsp_format = "fallback", range = range })
end, { range = true })

-- Copilot Chat setup
require("CopilotChat").setup {}

-- Key mappings for Copilot
vim.keymap.set('n', '<leader>cc', function()
	vim.cmd(':CopilotChatToggle')
	vim.cmd('wincmd L')
end, { desc = 'Open Copilot Chat' })

-- NERDTree setup
vim.keymap.set('n', '<leader>n', ':NERDTreeToggle<CR>', { desc = 'Toggle NERDTree' })

-- Telescope setup
local builtin = require 'telescope.builtin'

vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find Files' })
vim.keymap.set('n', '<leader>/', function()
	builtin.current_buffer_fuzzy_find({
		prompt_title = 'Search in Current Buffer',
	})
end, { desc = 'Search in Current Buffer' })

-- Floaterm setup
-- Lazygit key mapping
vim.keymap.set('n', '<leader>gg', ':FloatermNew --name=lg lazygit<CR>', { desc = 'Open Lazygit in Floaterm' })

-- Autocommands
vim.cmd [[
autocmd VimEnter * ++nested colorscheme kanso-mist
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
]]

-- Dark/light toggle command
vim.api.nvim_create_user_command("ToggleTheme", function()
  if vim.o.background == "dark" then
    vim.o.background = "light"
    vim.cmd.colorscheme("kanso-pearl")
  else
    vim.o.background = "dark"
    vim.cmd.colorscheme("kanso-mist")
  end
end, {})


vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.cmd [[
      hi StatusLine cterm=NONE gui=NONE
      hi TabLine cterm=NONE gui=NONE
      hi WinBar cterm=NONE gui=NONE
    ]]
  end,
})

-- Set up nvim-cmp.
local cmp = require'cmp'

cmp.setup({
  snippet = {
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
      -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
      -- vim.snippet.expand(args.body) -- For native neovim snippets (Neovim v0.10+)
      -- For `mini.snippets` users:
      -- local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
      -- insert({ body = args.body }) -- Insert at cursor
      -- cmp.resubscribe({ "TextChangedI", "TextChangedP" })
      -- require("cmp.config").set_onetime({ sources = {} })
    end,
  },
  window = {
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'vsnip' }, -- For vsnip users.
    -- { name = 'luasnip' }, -- For luasnip users.
    -- { name = 'ultisnips' }, -- For ultisnips users.
    -- { name = 'snippy' }, -- For snippy users.
  }, {
    { name = 'buffer' },
  })
})

-- To use git you need to install the plugin petertriho/cmp-git and uncomment lines below
-- cmp.setup.filetype('gitcommit', {
--   sources = cmp.config.sources({
--     { name = 'git' },
--   }, {
--     { name = 'buffer' },
--   })
-- })
-- require("cmp_git").setup()

-- Use buffer source for `/` and `?`
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

-- Use cmdline & path source for ':'
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  }),
  matching = { disallow_symbol_nonprefix_matching = false }
})

-- Set up lspconfig.
local capabilities = require('cmp_nvim_lsp').default_capabilities()
-- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
require('lspconfig')['<YOUR_LSP_SERVER>'].setup {
  capabilities = capabilities
}

