-- NOTE: Bootstrap vim-plug if missing
local data_dir = vim.fn.stdpath("data") .. "/site"
if vim.fn.empty(vim.fn.glob(data_dir .. "/autoload/plug.vim")) > 0 then
	vim.fn.system({
		"sh",
		"-c",
		"curl -fLo "
			.. data_dir
			.. "/autoload/plug.vim --create-dirs "
			.. "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim",
	})
	vim.cmd([[autocmd VimEnter * PlugInstall --sync | source $MYVIMRC]])
end

-- NOTE: vim-plug plugin manager
vim.cmd([[
call plug#begin('~/.vim/plugged')

Plug 'mattn/webapi-vim'

" NOTE: Theme
Plug 'webhooked/kanso.nvim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'edkolev/tmuxline.vim'

" NOTE: ALE (Asynchronous Lint Engine)
Plug 'dense-analysis/ale'

" NOTE: Conform formatter
Plug 'stevearc/conform.nvim'

" NOTE: NERDTree (File Explorer)
Plug 'nvim-tree/nvim-tree.lua'
Plug 'nvim-tree/nvim-web-devicons'

" NOTE: Rust support
Plug 'rust-lang/rust.vim'

" NOTE: Copilot and related plugins
Plug 'github/copilot.vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'CopilotC-Nvim/CopilotChat.nvim'

" NOTE: fzf
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" NOTE: Telescope
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.8' }

" NOTE: Treesitter (Syntax highlighting and more)
Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
Plug 'interdependence/tree-sitter-htmldjango' " For htmldjango support

" NOTE: Noice (Enhanced command line and notifications)
Plug 'folke/noice.nvim'
Plug 'MunifTanjim/nui.nvim'

" NOTE: Floaterm
Plug 'voldikss/vim-floaterm'

" NOTE: Nvim-cmp and related plugins
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'

" NOTE: Vsnip
Plug 'hrsh7th/cmp-vsnip'

" NOTE: Todo comments highlighting
Plug 'folke/todo-comments.nvim'

" NOTE: Obsidian.nvim
Plug 'epwalsh/obsidian.nvim'

call plug#end()
]])

-- NOTE: Set <space> as leader keymap
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- NOTE: General settings
local user = vim.env.USER or "User"
user = user:sub(1, 1):upper() .. user:sub(2) -- Capitalize first letter
vim.o.number = true
vim.o.backspace = "indent,eol,start"
vim.o.termguicolors = true
vim.cmd.colorscheme("kanso-mist")
vim.o.background = "dark"

-- NOTE: Todo comments setup
require("todo-comments").setup()

-- NOTE: Syntax and filetype plugins
vim.cmd([[
syntax enable
filetype plugin indent on
]])

-- NOTE: Airline config
vim.g.airline_powerline_fonts = 1
vim.g.airline_theme = "minimalist"
vim.g.airline_section_y = 'BN: %{bufnr("%")}'
vim.o.guifont = "JetBrainsMono Nerd Font"
vim.g["airline#extensions#tabline#enabled"] = 1
vim.g["airline#extensions#tabline#formatter"] = "default"

-- NOTE: NERDTree config
vim.keymap.set("n", "<leader>n", ":NvimTreeToggle<CR>", { desc = "Toggle NerdTree" })
-- Enable 24-bit color support
vim.opt.termguicolors = true
-- NERDTree settings
require("nvim-tree").setup()

-- NOTE: ALE linters/fixers for Rust
vim.g.ale_linters = { rust = { "analyzer" } }
vim.g.ale_fixers = { rust = { "rustfmt" } }

-- NOTE: Noice setup
require("noice").setup()

-- NOTE: Conform setup
require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		-- Conform will run multiple formatters sequentially
		python = { "isort", "black", "prettierd", stop_after_first = true },
		-- You can customize some of the format options for the filetype (:help conform.format)
		rust = { "rustfmt", lsp_format = "fallback" },
		-- Conform will run the first available formatter
		javascript = { "prettierd" },
		typescript = { "prettierd" },
		html = { "djhtml" },
		htmldjango = { "djhtml" },
	},
	formatters = {
		djhtml = {
			command = "djhtml",
			args = { "$FILENAME" },
			stdin = false,
		},
	},
	-- Save the formatted file after formatting
	format_on_save = {
		timeout_ms = 500, -- Timeout for formatting in milliseconds
		lsp_format = "fallback", -- Use LSP formatting as a fallback
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

-- NOTE: Copilot Chat setup
require("CopilotChat").setup({
	auto_insert_mode = true,
	question_header = "  " .. user .. ": ",
	answer_header = "  Copilot: ",
	error_header = "  Error: ",
	mappings = {
		complete = {
			insert = "<C-Tab>",
			normal = "<C-Tab>",
		},
	},
})

-- NOTE: Key mappings for Copilot
-- Toggle CopilotChat
vim.keymap.set("n", "<leader>cc", function()
	vim.cmd(":CopilotChatToggle")
	vim.cmd("wincmd L")
end, { desc = "Open Copilot Chat" })
-- Clear CopilotChat conversation
vim.keymap.set("n", "<leader>ax", function()
	-- Resets the CopilotChat conversation
	return require("CopilotChat").reset()
end, { desc = "Reset Copilot Chat" })
-- Quick chat prompt
vim.keymap.set("n", "<leader>cq", function()
	-- Opens a quick chat prompt
	vim.ui.input({ prompt = "Quick Chat: " }, function(input)
		if input ~= "" then
			require("CopilotChat").ask(input)
		end
	end)
	vim.cmd("wincmd L")
end, { desc = "Quick Chat with Copilot" })

-- NOTE: Telescope setup
local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
vim.keymap.set("n", "<leader>/", function()
	builtin.current_buffer_fuzzy_find({
		prompt_title = "Search in Current Buffer",
	})
end, { desc = "Search in Current Buffer" })

-- NOTE: Treesitter setup
require("nvim-treesitter.configs").setup({
	ensure_installed = { "markdown", "markdown_inline", ... },
	highlight = {
		enable = true,
	},
})

local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.htmldjango = {
	filetype = "htmldjango",
	install_info = {
		url = "https://github.com/interdependence/tree-sitter-htmldjango",
		files = { "src/parser.c" },
	},
	filetype = "htmljinja",
}

-- NOTE: Floaterm setup
-- NOTE: Lazygit key mapping
vim.keymap.set("n", "<leader>gg", ":FloatermNew --name=lg lazygit<CR>", { desc = "Open Lazygit in Floaterm" })

-- NOTE: Autocommands
vim.cmd([[
autocmd VimEnter * ++nested colorscheme kanso-mist
autocmd StdinReadPre * let s:std_in=1
]])

-- NOTE: Dark/light toggle command
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
		vim.cmd([[
      hi StatusLine cterm=NONE gui=NONE
      hi TabLine cterm=NONE gui=NONE
      hi WinBar cterm=NONE gui=NONE
    ]])
	end,
})

-- NOTE: Set up nvim-cmp.
local cmp = require("cmp")

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
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "vsnip" }, -- For vsnip users.
		-- { name = 'luasnip' }, -- For luasnip users.
		-- { name = 'ultisnips' }, -- For ultisnips users.
		-- { name = 'snippy' }, -- For snippy users.
	}, {
		{ name = "buffer" },
	}),
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
cmp.setup.cmdline({ "/", "?" }, {
	mapping = cmp.mapping.preset.cmdline(),
	sources = {
		{ name = "buffer" },
	},
})

-- Use cmdline & path source for ':'
cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({
		{ name = "path" },
	}, {
		{ name = "cmdline" },
	}),
	matching = { disallow_symbol_nonprefix_matching = false },
})

-- NOTE: Set up lspconfig.
local capabilities = require("cmp_nvim_lsp").default_capabilities()
-- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
require("lspconfig")["<YOUR_LSP_SERVER>"].setup({
	capabilities = capabilities,
})

-- NOTE: Set up Obsidian.nvim
require("obsidian").setup({
	workspaces = {
		{
			name = "vault",
			path = "/Users/conradomanclossi/Library/Mobile Documents/iCloud~md~obsidian/Documents/Conrado",
		},
	},
})
