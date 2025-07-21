return {
	-- You can set java development environment as like this.
	-- $HOME/java/jdk-21
	-- $HOME/java/jdtls
	-- $HOME/java/eclipse/workspace
	"mfussenegger/nvim-jdtls",
	ft = { "java" },
	config = function()
		local jdtls = require("jdtls")
		-- Determine OS
		local home = os.getenv("HOME")
		local workspace_path = home .. "/java/eclipse/workspace/"
		local function find_equinox_launcher_jars()
			local jars = {}
			local handle = io.popen("ls " ..
				home .. "/java/jdtls/plugins/org.eclipse.equinox.launcher*_*.jar 2>/dev/null")
			if handle then
				for line in handle:lines() do
					table.insert(jars, line)
					break
				end
				handle:close()
			end
			return jars
		end

		-- 사용 예시:
		local jdtls_jar = find_equinox_launcher_jars()[1]
		--
		-- 현재 운영체제(OS)를 확인하는 함수
		local function get_os()
			local os_name = vim.loop.os_uname().sysname
			if os_name == "Darwin" then
				local arch = vim.loop.os_uname().arch
				if arch == "arm" then
					return "mac_arm"
				else
					return "mac"
				end
			elseif os_name == "Linux" then
				return "linux"
			else
				return os_name -- 기타 OS 이름 반환
			end
		end

		local os_config = get_os()

		-- Find root of project
		-- local root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }
		local root_markers = { "mvnw", "gradlew", "pom.xml", "build.gradle", ".project", ".classpath" }
		local root_dir = require("jdtls.setup").find_root(root_markers)
		if root_dir == "" then
			return
		end

		local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
		local workspace_dir = workspace_path .. project_name

		-- Setup capabilities
		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)


		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
			callback = function(event)
				-- NOTE: Remember that Lua is a real programming language, and as such it is possible
				-- to define small helper and utility functions so you don't have to repeat yourself.
				--
				-- In this case, we create a function that lets us more easily define mappings specific
				-- for LSP related items. It sets the mode, buffer and description for us each time.
				local map = function(keys, func, desc)
					vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
				end

				-- Jump to the definition of the word under your cursor.
				--  This is where a variable was first declared, or where a function is defined, etc.
				--  To jump back, press <C-t>.
				map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
				map("<C-]>", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

				-- Find references for the word under your cursor.
				map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

				-- Jump to the implementation of the word under your cursor.
				--  Useful when your language has ways of declaring types without an actual implementation.
				map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

				-- Jump to the type of the word under your cursor.
				--  Useful when you're not sure what type a variable is and you want to see
				--  the definition of its *type*, not where it was *defined*.
				map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

				-- Fuzzy find all the symbols in your current document.
				--  Symbols are things like variables, functions, types, etc.
				map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

				-- Fuzzy find all the symbols in your current workspace.
				--  Similar to document symbols, except searches over your entire project.
				map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

				-- Rename the variable under your cursor.
				--  Most Language Servers support renaming across files, etc.
				map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

				-- Execute a code action, usually your cursor needs to be on top of an error
				-- or a suggestion from your LSP for this to activate.
				map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

				-- Opens a popup that displays documentation about the word under your cursor
				--  See `:help K` for why this keymap.
				map("K", vim.lsp.buf.hover, "Hover Documentation")

				-- WARN: This is not Goto Definition, this is Goto Declaration.
				--  For example, in C this would take you to the header.
				map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
			end
		})


		-- 1. on_attach 함수 정의
		local function on_attach(client, bufnr)
			print(client.name .. ">>>> attached to buffer: " .. bufnr)
		end

		-- Configure JDTLS
		local config = {
			on_attach = on_attach,
			settings = {
				java = {
					-- Add your Java settings here
					-- Example: format settings, checkstyle, etc.
					configuration = {
						runtimes = {
							{
								name = "JavaSE-21",
								path = home .. "/java/jdk-21/",
							},
							{
								name = "JavaSE-11",
								path = home .. "/java/jdk-11/",
							},
							{
								name = "JavaSE-17",
								path = home .. "/java/jdk-17/",
							},
							{
								name = "JavaSE-1.8",
								path = home .. "/java/jdk-1.8/",
							},
						},
					},
					-- Specify any completion options
					completion = {
						favoriteStaticMembers = {
							"org.hamcrest.MatcherAssert.assertThat",
							"org.hamcrest.Matchers.*",
							"org.hamcrest.CoreMatchers.*",
							"org.junit.jupiter.api.Assertions.*",
							"java.util.Objects.requireNonNull",
							"java.util.Objects.requireNonNullElse",
							"org.mockito.Mockito.*"
						},
						filteredTypes = {
							"com.sun.*",
							"io.micrometer.shaded.*",
							"java.awt.*",
							"jdk.*", "sun.*",
						},
					},
				},
			},
			cmd = {
				"java",
				"-Declipse.application=org.eclipse.jdt.ls.core.id1",
				"-Dosgi.bundles.defaultStartLevel=4",
				"-Declipse.product=org.eclipse.jdt.ls.core.product",
				"-Dlog.protocol=true",
				"-Dlog.level=ALL",
				"-Xms1g",
				"-jar", jdtls_jar,
				"-configuration", home .. "/java/jdtls/config_" .. os_config,
				"-data", workspace_dir,
			},
			root_dir = root_dir,
			capabilities = capabilities,
		}

		-- Start or attach JDTLS
		jdtls.start_or_attach(config)

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "java",
			callback = function()
				local jdtls = require("jdtls")

				-- 현재 버퍼에 jdtls가 attach되어 있는지 확인
				local active_clients = vim.lsp.get_active_clients({ bufnr = 0 })
				local jdtls_attached = false
				for _, client in ipairs(active_clients) do
					if client.name == "jdtls" then
						jdtls_attached = true
						break
					end
				end

				-- attach 되어 있지 않으면 start_or_attach 호출
				if not jdtls_attached then
					jdtls.start_or_attach(config)
				end
			end,
		})
	end,
	-- Automatically attach JDTLS when opening a Java file
}
