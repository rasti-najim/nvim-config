return {
	-- REPL integration for Lisp dialects (Scheme, Racket, Clojure, Fennel, etc.)
	{
		"Olical/conjure",
		ft = { "scheme", "racket", "clojure", "fennel" },
		init = function()
			vim.g["conjure#filetype#scheme"] = "conjure.client.scheme.stdio"
		end,
	},
	-- Parinfer: keeps parens balanced based on indentation
	{
		"gpanders/nvim-parinfer",
		ft = { "scheme", "racket", "clojure", "fennel", "lisp" },
	},
}
