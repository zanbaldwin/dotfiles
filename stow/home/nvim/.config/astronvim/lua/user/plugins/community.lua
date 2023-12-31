return {
    -- Add the community repository of plugin specifications
    "AstroNvim/astrocommunity",
    -- example of importing a plugin, comment out to use it or add your own
    -- available plugins can be found at https://github.com/AstroNvim/astrocommunity

    -- For dealing with NVim configuration
    { import = "astrocommunity.pack.lua" },

    -- Useful for dealing with scripting but not actual programming
    { import = "astrocommunity.pack.json" },
    { import = "astrocommunity.pack.markdown" },
    { import = "astrocommunity.pack.yaml" },

    -- Colour schemes (haven't decided on a favourite yet)
    { import = "astrocommunity.colorscheme.dracula-nvim" },
    { import = "astrocommunity.colorscheme.vscode-nvim" },

    -- Other
    { import = "astrocommunity.completion.copilot-lua" },

    -- Languages
    { import = "astrocommunity.pack.bash" },
    { import = "astrocommunity.pack.php" },
    { import = "astrocommunity.pack.rust" },

    -- Use `cargo clippy` instead of `cargo check`.
    lsp = {
        config = {
            rust_analyzer = {
                settings = {
                    -- Add clippy lints for Rust.
                    checkOnSave = {
                        allFeatures = true,
                        command = "clippy",
                        extraArgs = { "--no-deps" },
                    },
                },
            },
        },
    },
}
