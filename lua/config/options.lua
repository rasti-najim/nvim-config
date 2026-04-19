vim.g.mapleader = " "

vim.o.number = true
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.list = true
vim.o.confirm = true

vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

vim.cmd("packadd! nohlsearch")
