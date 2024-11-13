return {
	"preservim/tagbar",
	config = function()
		local keymap = vim.keymap
		keymap.set("n", "<F5>", "<cmd>TagbarToggle<CR>", { desc = "Toggle file explorer" }) -- toggle file explorer
	end,
}
