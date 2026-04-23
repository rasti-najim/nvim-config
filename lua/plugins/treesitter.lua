return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").setup({
			ensure_installed = { "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "scheme", "racket" },
			auto_install = true,
		})
	end,
}
