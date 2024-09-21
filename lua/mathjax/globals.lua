local Path = require("plenary.path")

local temp = vim.fn.tempname()
local stale_images = {}

local temp_dir = Path:new(temp)
temp_dir:mkdir({ parents = true })

local default_config = {
	color = 'White'
}

return {
	temp_dir = temp,
	stale_images = stale_images,
	config = default_config,
}
