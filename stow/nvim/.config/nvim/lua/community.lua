-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
    "AstroNvim/astrocommunity",

    -- Packs
    { import = "astrocommunity.pack.bash" },
    { import = "astrocommunity.pack.docker" },
    { import = "astrocommunity.pack.html-css" },
    { import = "astrocommunity.pack.json" },
    { import = "astrocommunity.pack.lua" },
    { import = "astrocommunity.pack.markdown" },
    { import = "astrocommunity.pack.nix" },
    -- PHP requires: PHP, Composer.
    { import = "astrocommunity.pack.php" },
    { import = "astrocommunity.pack.rust" },
    { import = "astrocommunity.pack.sql" },
    { import = "astrocommunity.pack.toml" },
    { import = "astrocommunity.pack.yaml" },

    -- Colour Schemes
    { import = "astrocommunity.colorscheme.catppuccin" },
    { import = "astrocommunity.colorscheme.dracula-nvim" },
    -- colorscheme "github_dark_dimmed"
    { import = "astrocommunity.colorscheme.github-nvim-theme" },
    -- colorscheme "monokai-pro"
    { import = "astrocommunity.colorscheme.monokai-pro-nvim" },
    -- colorscheme "nordic"
    { import = "astrocommunity.colorscheme.nordic-nvim" },

}
