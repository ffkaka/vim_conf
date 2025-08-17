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
		local os_config = "linux"

		-- Setup capabilities
		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

		-- eclipse.jdt.launcher file 찾기
		-- 정확한 버전의 org.eclipse.equinox.launcher_*.jar 형태의 파일을 찾아주기
		local function find_eclipse_launcher()
			local launcher_path = home .. "/java/jdtls/plugins/"
			local files = vim.fn.glob(launcher_path .. "org.eclipse.equinox.launcher_*.jar", false, true)
			if #files == 0 then
				error("No org.eclipse.equinox.launcher_*.jar found in " .. launcher_path)
			end
			return files[1] -- 첫 번째 파일을 반환
		end
		local launcher_jar = find_eclipse_launcher()

		-- 1. on_attach 함수 정의 (키맵 설정 포함)
		local function on_attach(client, bufnr)
			print(client.name .. " attached to buffer: " .. bufnr)

			-- 키맵 설정을 여기서 처리
			local map = function(keys, func, desc)
				vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
			end

			-- LSP 키맵들
			map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
			map("<C-]>", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
			map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
			map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
			map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
			map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
			map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
			map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
			map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
			map("K", vim.lsp.buf.hover, "Hover Documentation")
			map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
		end

		-- JDTLS 설정 함수
		local function setup_jdtls()
			-- Find root of project
			local root_markers = { "mvnw", "gradlew", "pom.xml", "build.gradle", ".project", ".classpath" }
			local root_dir = require("jdtls.setup").find_root(root_markers)
			if root_dir == "" then
				return
			end

			local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
			local workspace_dir = workspace_path .. project_name

			-- Configure JDTLS
			local config = {
				on_attach = on_attach,
				settings = {
					java = {
						configuration = {
							runtimes = {
								{
									name = "JavaSE-21",
									path = home .. "/java/jdk-21",
								},
								{
									name = "JavaSE-11",
									path = home .. "/java/jdk-11",
								},
								{
									name = "JavaSE-17",
									path = home .. "/java/jdk-17",
								},
								{
									name = "JavaSE-1.8",
									path = home .. "/java/jdk-1.8",
								},
							},
						},
						completion = {
							favoriteStaticMembers = {
								"org.hamcrest.MatcherAssert.assertThat",
								"org.hamcrest.Matchers.*",
								"org.hamcrest.CoreMatchers.*",
								"org.junit.jupiter.api.Assertions.*",
								"java.util.Objects.requireNonNull",
								"java.util.Objects.requireNonNullElse",
								"org.mockito.Mockito.*",
							},
							filteredTypes = {
								"com.sun.*",
								"io.micrometer.shaded.*",
								"java.awt.*",
								"jdk.*",
								"sun.*",
							},
						},
					},
				},
				cmd = {
					os.getenv("JAVA_HOME") .. "/bin/java",
					"-Declipse.application=org.eclipse.jdt.ls.core.id1",
					"-Dosgi.bundles.defaultStartLevel=4",
					"-Declipse.product=org.eclipse.jdt.ls.core.product",
					"-Dlog.protocol=true",
					"-Dlog.level=ALL",
					"-Xms1g",
					"-jar",
					launcher_jar,
					"-configuration",
					home .. "/java/jdtls/config_" .. os_config,
					"-data",
					workspace_dir,
				},
				root_dir = root_dir,
				capabilities = capabilities,
			}

			-- Start or attach JDTLS
			jdtls.start_or_attach(config)
		end

		-- 고유한 augroup 이름 사용
		local jdtls_group = vim.api.nvim_create_augroup("jdtls-java-setup", { clear = true })

		-- FileType autocmd - 성능 최적화
		vim.api.nvim_create_autocmd("FileType", {
			group = jdtls_group,
			pattern = "java",
			callback = function(args)
				-- 버퍼별로 한 번만 실행되도록 체크
				if vim.b[args.buf].jdtls_setup_done then
					return
				end

				-- 지연 실행으로 성능 개선
				vim.defer_fn(function()
					-- 버퍼가 여전히 유효한지 확인
					if not vim.api.nvim_buf_is_valid(args.buf) then
						return
					end

					-- 이미 JDTLS가 attach되어 있는지 확인 (효율적인 방법)
					local clients = vim.lsp.get_clients({ bufnr = args.buf, name = "jdtls" })
					if #clients == 0 then
						setup_jdtls()
					end

					-- 플래그 설정하여 중복 실행 방지
					vim.b[args.buf].jdtls_setup_done = true
				end, 100) -- 100ms 지연
			end,
		})

		-- 버퍼가 삭제될 때 플래그 정리
		vim.api.nvim_create_autocmd("BufDelete", {
			group = jdtls_group,
			pattern = "*.java",
			callback = function(args)
				vim.b[args.buf].jdtls_setup_done = nil
			end,
		})
	end,
}
