local Path = require("plenary.path")
local Job = require("plenary.job")
local api = require("image")
local globals = require("mathjax.globals")

local query_function = vim.treesitter.query.parse(
	"latex",
	[[
(displayed_equation _) @to_render
]]
)

local parent = Path:new(vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h")):parent():parent()
local mathjax_dir = Path:new(parent, Path:new("mathjax")).filename

local M = {}

function M.render_latex()
	local syntax_tree = vim.treesitter.get_parser(0, "latex", {}):parse()
	local root = syntax_tree[1]:root()

	for _, i in ipairs(api.get_images()) do
		i:clear()
		globals.stale_images[i.id] = true
	end

	for _, match, _ in query_function:iter_matches(root, 0, nil, nil, { all = true }) do
		for _, nodes in pairs(match) do
			-- local capture = query_function.captures[id]
			for _, matched_node in ipairs(nodes) do
				local latex_text = vim.treesitter.get_node_text(matched_node, 0, {})
				local range = vim.treesitter.get_range(matched_node, 0, nil)
				local height = range[4] - range[1] + 1
				latex_text = string.gsub(latex_text, "%$%$", "")
				-- FIXME: Thie should be done via treesitter, but I'm too lazy
				for line in string.gmatch(latex_text, "%% Lines: (%d*)") do
					local line_parsed = tonumber(line)
					if line_parsed ~= nil then
						height = line_parsed
					end
				end
				-- FIXME: Use this hash to see if we need to replace or not.
				local num = vim.fn.sha256(latex_text)
				local url = globals.temp_dir .. "/" .. tostring(num) .. ".png"
				local curr_win = vim.api.nvim_get_current_win()
				local curr_buf = vim.api.nvim_get_current_buf()
				Job:new({
					command = "node",
					args = { "index.js", url, latex_text },
					cwd = mathjax_dir,
					raw_args = true,
					on_exit = function(result, r)
						vim.schedule(function()
							vim.print(result)
							vim.print(r)
						end)
						local image = api.from_file(url, {
							window = curr_win,
							buffer = curr_buf,
							with_virtual_padding = true,
							inline = true,
							x = 0,
							height = height,
							y = range[4],
						})
						vim.schedule(function()
							vim.print(result)
							vim.print(r)
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
end

-- vim.api.nvim_create_autocmd("BufWritePost", {
-- 	pattern = "*.md",
-- 	callback = run,
-- })

M.render_latex()

return M
