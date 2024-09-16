local Job = require("plenary.job")
local api = require("image")
local globals = require("globals")

-- vim.print(globals.temp_dir)
-- vim.print(globals.stale_images)

for _, i in ipairs(api.get_images()) do
	i:clear()
	globals.stale_images[i.id] = true
	-- FIXME: cleanup stale images (remove them)
end

local syntax_tree = vim.treesitter.get_parser(0, "latex", {}):parse()
local root = syntax_tree[1]:root()
local query_function = vim.treesitter.query.parse(
	"latex",
	[[
(displayed_equation _) @to_render
]]
)

for _, match, _ in query_function:iter_matches(root, 0, nil, nil, { all = true }) do
	for _, nodes in pairs(match) do
		for _, matched_node in ipairs(nodes) do
			local latex_text = vim.treesitter.get_node_text(matched_node, 0, {})
			local range = vim.treesitter.get_range(matched_node, 0, nil)
			latex_text = string.gsub(latex_text, "%$%$", "")
			latex_text = string.gsub(latex_text, "\n", "")
			-- FIXME: Hash rather than random?
			local num = vim.fn.sha256(latex_text)
			local url = globals.temp_dir .. "/" .. tostring(num) .. ".png"
			local curr_win = vim.api.nvim_get_current_win()
			local curr_buf = vim.api.nvim_get_current_buf()
			Job:new({
				command = "node",
				args = { "mathjax/index.js", url, latex_text },
				raw_args = true,
				on_exit = function(code, signal)
					local image = api.from_file(url, {
						-- namespace = "latex",
						window = curr_win,
						buffer = curr_buf,
						with_virtual_padding = true,
						inline = true,
						x = 0,
						height = range[4] - range[1] + 1,
						y = range[1] - 1,
					})
					vim.schedule(function()
						if image ~= nil then
							local has_rendered = true
							image:render() -- render image
							globals.stale_images[image.id] = false
							vim.api.nvim_create_autocmd("BufEnter", {
								callback = function()
									if
										globals.stale_images[image.id] == false
										and has_rendered == false
										and vim.api.nvim_get_current_buf() == curr_buf
									then
										image:render()
										has_rendered = true
									else
										image:clear()
										has_rendered = false
									end
								end,
							})
						end
					end)
				end,
			}):start()
		end
	end
end
