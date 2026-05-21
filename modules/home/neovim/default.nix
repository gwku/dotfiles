{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = with pkgs.vimPlugins; [
      # Core
      plenary-nvim
      nvim-web-devicons

      # Theme
      catppuccin-nvim

      # UI
      lualine-nvim
      bufferline-nvim
      which-key-nvim
      nvim-tree-lua
      gitsigns-nvim
      indent-blankline-nvim

      # Treesitter
      nvim-treesitter.withAllGrammars
      nvim-treesitter-textobjects

      # LSP + completion
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp_luasnip
      luasnip
      friendly-snippets

      # Formatter
      conform-nvim

      # Fuzzy finder
      telescope-nvim
      telescope-fzf-native-nvim
    ];

    extraPackages = with pkgs; [
      ripgrep
      fd

      # LSP servers
      lua-language-server
      nil
      pyright
      typescript-language-server
      bash-language-server
      nixd
      gopls
      rust-analyzer

      # Formatters
      stylua
      nixpkgs-fmt
      black
      shfmt
      nodePackages.prettier
    ];

    extraLuaConfig = ''
      require('options')
      require('keymaps')
      require('plugins')
    '';
  };

  xdg.configFile."nvim/lua".source = ./lua;
}
