-- Customize None-ls sources

---@type LazySpec
return {
    "nvimtools/none-ls.nvim",
    opts = function(_, config)
        -- config variable is the default configuration table for the setup function call
        local null_ls = require "null-ls"

        -- Check supported formatters and linters
        -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/formatting
        -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
        config.sources = {
            null_ls.builtins.diagnostics.checkmake,
            null_ls.builtins.diagnostics.commitlint,
            null_ls.builtins.diagnostics.dotenv_linter,
            null_ls.builtins.diagnostics.editorconfig_checker,
            null_ls.builtins.diagnostics.markdownlint,
            null_ls.builtins.diagnostics.phpstan,
            null_ls.builtins.diagnostics.twigcs,
            null_ls.builtins.diagnostics.yamllint,
            null_ls.builtins.diagnostics.checkmake,
            null_ls.builtins.diagnostics.checkmake,
            null_ls.builtins.diagnostics.checkmake,

            null_ls.builtins.formatting.nixfmt,
            null_ls.builtins.formatting.nixpkgs_fmt,
            null_ls.builtins.formatting.phpcsfixer,
            null_ls.builtins.formatting.shellharden,
        }
        return config -- return final config table
    end,
}
