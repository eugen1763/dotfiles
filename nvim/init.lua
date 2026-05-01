require("config.lazy")

vim.diagnostic.config({
	virtual_text = true, -- this is the inline error text
})

vim.keymap.set("n", "<leader>df", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format file" })

vim.o.tabstop = 4 -- A TAB character looks like 4 spaces
vim.o.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
vim.o.softtabstop = 4 -- Number of spaces inserted instead of a TAB character
vim.o.shiftwidth = 4 -- Number of spaces inserted when indenting
