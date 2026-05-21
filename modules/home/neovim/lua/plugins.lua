-- Plugins are installed by Nix; this file only configures them.

-- Theme
require("catppuccin").setup({
  flavour = "mocha",
  transparent_background = false,
  integrations = {
    cmp = true,
    gitsigns = true,
    nvimtree = true,
    telescope = { enabled = true },
    treesitter = true,
    which_key = true,
  },
})
vim.cmd.colorscheme("catppuccin")

-- Statusline / bufferline
require("lualine").setup({
  options = {
    theme = "catppuccin",
    icons_enabled = true,
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
  },
})

require("bufferline").setup({
  options = {
    diagnostics = "nvim_lsp",
    show_buffer_close_icons = false,
    show_close_icon = false,
  },
})

-- File tree
require("nvim-tree").setup({
  view = { width = 36 },
  renderer = { group_empty = true },
  filters = { dotfiles = false },
})

-- Git
require("gitsigns").setup()

-- Indent guides
require("ibl").setup({ scope = { enabled = true } })

-- Which-key
require("which-key").setup()

-- Treesitter
require("nvim-treesitter.configs").setup({
  highlight = { enable = true },
  indent    = { enable = true },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection    = "<C-space>",
      node_incremental  = "<C-space>",
      scope_incremental = false,
      node_decremental  = "<bs>",
    },
  },
})

-- Telescope
local telescope = require("telescope")
telescope.setup({
  defaults = {
    layout_strategy = "horizontal",
    sorting_strategy = "ascending",
    layout_config = { prompt_position = "top" },
  },
})
pcall(telescope.load_extension, "fzf")

-- LSP
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lspconfig = require("lspconfig")

local servers = {
  lua_ls = {
    settings = {
      Lua = {
        diagnostics = { globals = { "vim" } },
        workspace = { checkThirdParty = false },
      },
    },
  },
  nil_ls = {},
  nixd = {},
  pyright = {},
  ts_ls = {},
  bashls = {},
  gopls = {},
  rust_analyzer = {},
}

for server, cfg in pairs(servers) do
  cfg.capabilities = capabilities
  lspconfig[server].setup(cfg)
end

-- Completion
local cmp = require("cmp")
local luasnip = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"]     = cmp.mapping.abort(),
    ["<CR>"]      = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
      else fallback() end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then luasnip.jump(-1)
      else fallback() end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip"  },
    { name = "buffer"   },
    { name = "path"     },
  }),
})

-- Formatter
require("conform").setup({
  formatters_by_ft = {
    lua        = { "stylua" },
    nix        = { "nixpkgs_fmt" },
    python     = { "black" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    json       = { "prettier" },
    yaml       = { "prettier" },
    markdown   = { "prettier" },
    sh         = { "shfmt" },
  },
  format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
})
