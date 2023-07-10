local M = {
	"echasnovski/mini.animate",
	version = false,
}

function M.config()
	local mouse_scrolled = false
	for _, scroll in ipairs({ "Up", "Down" }) do
		local key = "<ScrollWheel" .. scroll .. ">"
		vim.keymap.set("", key, function()
			mouse_scrolled = true
			return key
		end, { remap = true, expr = true })
	end
	require("mini.animate").setup({
		scroll = {
			subscroll = require("mini.animate").gen_subscroll.equal({
				predicate = function(total_scroll)
					if mouse_scrolled then
						mouse_scrolled = false
						return false
					end
					return total_scroll > 1
				end,
			}),
		},
	})
end

return M
