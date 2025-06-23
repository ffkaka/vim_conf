return {
	"fatih/vim-go",
	config = function()
		vim.g.go_imports_autosave = 0
		vim.g.go_completion_enabled = 1
		vim.g.go_completion_auto_type = 0
		vim.g.go_completion_auto_gopkgs = 1
		vim.g.go_imports_mode = "goimports"
	end,
}
