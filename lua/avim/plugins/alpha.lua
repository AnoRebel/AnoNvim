local M = {
	"goolord/alpha-nvim",
	lazy = false,
}

function M.config()
	local alpha = require("alpha")
	local fortune = require("alpha.fortune")
	local greeting = require("avim.utils").get_greeting("Rebel")
	local banner = require("avim.utils.banners")["random"]

	--- @param sc string
	--- @param txt string
	--- @param keybind string? optional
	--- @param keybind_opts table? optional
	local function button(sc, txt, keybind, keybind_opts)
		local sc_ = sc:gsub("%s", ""):gsub("SPC", "<leader>")

		local opts = {
			position = "center",
			-- text = txt,
			shortcut = sc,
			cursor = 5,
			width = 50,
			align_shortcut = "right",
			hl = "AlphaButtons",
		}

		if keybind then
			keybind_opts = vim.F.if_nil(keybind_opts, { noremap = true, silent = true, nowait = true })
			opts.keymap = { "n", sc_, keybind, keybind_opts }
		end

		return {
			type = "button",
			val = txt,
			on_press = function()
				local key = vim.api.nvim_replace_termcodes(keybind or sc_ .. "<Ignore>", true, false, true)
				vim.api.nvim_feedkeys(key, "t", false)
			end,
			opts = opts,
		}
	end

	local section = {}

	section.header = {
		type = "text",
		val = banner,
		opts = {
			position = "center",
			hl = "AlphaHeader",
		},
	}

	section.greetings = {
		type = "text",
		val = greeting,
		opts = {
			position = "center",
			hl = "String",
		},
	}

	-- ╭──────────────────────────────────────────────────────────╮
	-- │ Heading Info                                             │
	-- ╰──────────────────────────────────────────────────────────╯

	local thingy = io.popen('echo "$(date +%a) $(date +%d) $(date +%b)" | tr -d "\n"')
	if thingy == nil then
		return
	end
	local date = thingy:read("*a")
	thingy:close()

	local datetime = os.date(" %H:%M")

	section.hi_top_section = {
		type = "text",
		val = "┌────────────   Today is "
			.. date
			.. " ────────────┐",
		opts = {
			position = "center",
			hl = "String", -- AlphaLoaded
		},
	}

	section.hi_middle_section = {
		type = "text",
		val = "│                                                │",
		opts = {
			position = "center",
			hl = "String",
		},
	}

	section.hi_bottom_section = {
		type = "text",
		val = "└───══───══───══───  "
			.. datetime
			.. "  ───══───══───══────┘",
		opts = {
			position = "center",
			hl = "String",
		},
	}

	section.buttons = {
		type = "group",
		val = {
			-- button("SPC e", "  > New file" , ":ene <BAR> startinsert <CR>"),
			button("SPC f f", "  Find File  ", ":Telescope find_files<CR>"),
			button("SPC f o", "  Recent File  ", ":Telescope oldfiles<CR>"),
			button("SPC f w", "  Find Word  ", ":Telescope live_grep<CR>"),
			button("SPC k m", "  Mappings  ", ":Telescope keymaps<CR>"),
			button("SPC e s", "  Settings", ":e $MYVIMRC | :cd %:p:h | split . | wincmd k | pwd<CR>"),
			button("SPC q", "  Quit", "<Cmd>qa<CR>"),
		},
		opts = {
			spacing = 1,
		},
	}

	local footer = function()
		local stats = require("lazy").stats()
		local v = vim.version()
		local platform = vim.fn.has("win32") == 1 and "" or ""
		return string.format(
			" v%d.%d.%d | Took %.2f ms to load  %d of %d plugins on  %s",
			v.major,
			v.minor,
			v.patch,
			(math.floor(stats.startuptime * 100 + 0.5) / 100),
			stats.loaded,
			stats.count,
			platform
		)
		-- return string.format(" v%d.%d.%d   %d  %s", v.major, v.minor, v.patch, plugins, platform)
	end

	section.footer = {
		type = "text",
		val = { footer() },
		opts = {
			position = "center",
			hl = "Keyword",
		},
	}

	section.message = {
		type = "text",
		val = fortune({ max_width = 60 }),
		opts = {
			position = "center",
			hl = "Statement",
		},
	}

	alpha.setup({
		layout = {
			{ type = "padding", val = 2 },
			section.header,
			{ type = "padding", val = 1 },
			section.hi_top_section,
			section.hi_middle_section,
			section.greetings,
			section.hi_middle_section,
			section.hi_bottom_section,
			{ type = "padding", val = 1 },
			-- section.buttons,
			-- { type = "padding", val = 1 },
			section.footer,
			{ type = "padding", val = 1 },
			section.message,
		},
		opts = {
			margin = 5,
		},
	})
end

return M
