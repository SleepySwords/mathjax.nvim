local Path = require("plenary.path")
local Job = require("plenary.job")
local api = require("image")
local globals = require("mathjax.globals")

local parent = Path:new(vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h")):parent():parent()
local mathjax_dir = Path:new(parent, Path:new("mathjax")).filename
local config = globals.config

local M = {}

--- @class Config
--- @field color? string

--- Setup this plugin
--- @param new_config? Config
function M.setup(new_config)
	-- FIXME: validate
	config = vim.tbl_extend("force", config, new_config)
end

local function render_image(url, win, buff, x, y, height)
	local image = api.from_file(tostring(url), {
		window = win,
		buffer = buff,
		with_virtual_padding = true,
		inline = true,
		x = 0,
		height = height,
		y = y,
	})
	if image ~= nil then
		local has_rendered = true
		image:render() -- render image
		local autocmd_id = vim.api.nvim_create_autocmd("BufEnter", {
			callback = function()
				if has_rendered == false and buff == vim.api.nvim_get_current_buf() then
					image:render()
					has_rendered = true
				else
					image:clear()
					has_rendered = false
				end
			end,
		})
		globals.autocmd_ids[image.id] = autocmd_id
	end
end

--- Creates a job to render an image and put the image on the screen for this node
--- @param matched_node TSNode
--- @param con Config
local function handle_matched_node(matched_node, con)
	local latex_text = vim.treesitter.get_node_text(matched_node, 0, {})
	local range = vim.treesitter.get_range(matched_node, 0, nil)
	local height = range[4] - range[1] + 1
	latex_text = string.gsub(latex_text, "%$%$", "")
	for line in string.gmatch(latex_text:lower(), "%% lines: (%d*)") do
		local line_parsed = tonumber(line)
		if line_parsed ~= nil then
			height = line_parsed
		end
	end
	-- FIXME: Use this hash to see if we need to replace or not.
	local num = vim.fn.sha256(latex_text .. con.color)
	local url = Path:new(globals.temp_dir, tostring(num) .. ".png")
	-- FIXME: do all windows with the current buffer.
	local curr_win = vim.api.nvim_get_current_win()
	local curr_buf = vim.api.nvim_get_current_buf()
	if url:exists() then
		render_image(tostring(url), curr_win, curr_buf, 0, range[4], height)
	else
		Job:new({
			command = "node",
			args = { "index.js", tostring(url), con.color, latex_text },
			cwd = mathjax_dir,
			raw_args = true,
			on_exit = function(_result, _r)
				vim.schedule(function()
					render_image(tostring(url), curr_win, curr_buf, 0, range[4], height)
				end)
			end,
		}):start()
	end
end

--- Render the latex for this buffer.
--- @param local_config? Config
function M.render_latex(local_config)
	local con

	if local_config ~= nil then
		con = vim.tbl_extend("force", config, local_config)
	else
		con = config
	end

	local query_function = vim.treesitter.query.parse(
		"markdown_inline",
		[[
		(latex_block _) @to_render
		]]
	)
	local syntax_tree = vim.treesitter.get_parser(0, "markdown_inline", {}):parse()
	local root = syntax_tree[1]:root()

	for _, i in ipairs(api.get_images()) do
		i:clear()

		vim.api.nvim_del_autocmd(globals.autocmd_ids[i.id])
		globals.autocmd_ids[i.id] = nil
	end

	for _, match, _ in query_function:iter_matches(root, 0, nil, nil, { all = true }) do
		for _, nodes in pairs(match) do
			-- local capture = query_function.captures[id]
			for _, matched_node in ipairs(nodes) do
				handle_matched_node(matched_node, con)
			end
		end
	end
end

vim.api.nvim_create_user_command("Mathjax", function()
	M.render_latex()
end, { desc = "Render the mathjax blocks in the current buffer." })

return M
