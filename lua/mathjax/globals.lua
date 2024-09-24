local Path = require("plenary.path")

local temp = vim.fn.tempname()
local autocmd_ids = {}

local temp_dir = Path:new(temp)
temp_dir:mkdir({ parents = true })

local default_config = {
	color = 'White'
}

return {
	temp_dir = temp,
	autocmd_ids = autocmd_ids,
	config = default_config,
}
