return {
	-- Fuzzy picker
	{
		"ibhagwan/fzf-lua",
		config = function()
			require("fzf-lua").setup({ fzf_colors = true })
		end,
	},
	-- Enhanced quickfix/loclist
	{
		"stevearc/quicker.nvim",
		config = function()
			require("quicker").setup({})
		end,
	},
	-- Git integration
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({})
		end,
	},
	-- Auto-pairs
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	},
	-- Surround
	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},
	-- Which-key
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			require("which-key").setup({})
		end,
	},
}
