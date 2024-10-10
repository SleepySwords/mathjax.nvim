local Path = require("plenary.path")
local Job = require("plenary.job")
local api = require("image")
local globals = require("mathjax.globals")

local parent = Path
  :new(vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h"))
  :parent()
  :parent()
local mathjax_dir = Path:new(parent, Path:new("mathjax")).filename
local config = globals.config
local mathjax_namespace = vim.api.nvim_create_namespace("mathjax_inlines")

local latex_images = {}

local M = {}

--- @class Config
--- @field color? string

--- @class LatexImage

--- Setup this plugin
--- @param new_config? Config
function M.setup(new_config)
  -- FIXME: validate
  config = vim.tbl_extend("force", config, new_config)
end

local function render_image(url, win, buff, x, y, height, virtual_padding)
  local image = api.from_file(tostring(url), {
    window = win,
    buffer = buff,
    with_virtual_padding = virtual_padding,
    inline = true,
    x = x,
    height = height,
    y = y,
  })

  latex_images[image.id] = {
    shown = true,
    buf_enter_autocmd = nil,
  }

  if image ~= nil then
    image:render() -- render image
    local autocmd_id = vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        if
          latex_images[image.id].shown == false
          and buff == vim.api.nvim_get_current_buf()
          and win == vim.api.nvim_get_current_win()
        then
          image:render()
          latex_images[image.id].shown = true
        else
          image:clear()
          latex_images[image.id].shown = false
        end
      end,
    })
    latex_images[image.id].buf_enter_autocmd = autocmd_id
  end
  return image
end

local function register_inline_images_autocmds(
  buffer,
  win,
  image,
  x,
  y,
  image_width
)
  if latex_images[image.id].inline_extmark ~= nil then
    vim.api.nvim_buf_del_extmark(
      0,
      mathjax_namespace,
      latex_images[image.id].inline_extmark
    )
    latex_images[image.id].inline_extmark = nil
  end
  latex_images[image.id].inline_extmark =
    vim.api.nvim_buf_set_extmark(0, mathjax_namespace, y, x, {
      virt_text_pos = "inline",
      virt_text = { { (" "):rep(image_width) } },
    })
  local cursor_move_cmd = vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buffer,
    callback = function()
      if vim.api.nvim_get_current_win() ~= win then
        return
      end
      local cursor = vim.api.nvim_win_get_cursor(0)
      if cursor[1] - 1 == y then
        image:clear()
        if latex_images[image.id].inline_extmark ~= nil then
          vim.api.nvim_buf_del_extmark(
            0,
            mathjax_namespace,
            latex_images[image.id].inline_extmark
          )
          latex_images[image.id].inline_extmark = nil
        end
        latex_images[image.id].shown = false
      else
        -- FIXME: ensure this is the correct buffer...
        if latex_images[image.id].shown == false then
          if latex_images[image.id].inline_extmark ~= nil then
            vim.api.nvim_buf_del_extmark(
              0,
              mathjax_namespace,
              latex_images[image.id].inline_extmark
            )
            latex_images[image.id].inline_extmark = nil
          end
          latex_images[image.id].inline_extmark =
            vim.api.nvim_buf_set_extmark(0, mathjax_namespace, y, x, {
              virt_text_pos = "inline",
              virt_text = { { (" "):rep(image_width) } },
            })
          image:render()
          latex_images[image.id].shown = true
        end
      end
    end,
  })
  latex_images[image.id].cursor_move_cmd = cursor_move_cmd
end

local function create_job_and_render(text, colour, x, y, height, inline)
  local num = vim.fn.sha256(text .. colour)
  local url = Path:new(globals.temp_dir, tostring(num) .. ".png")
  local curr_buf = vim.api.nvim_get_current_buf()
  local current_buf_windows = vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_buf(win) == curr_buf
  end, vim.api.nvim_tabpage_list_wins(0))
  for _, curr_win in ipairs(current_buf_windows) do
    if url:exists() then
      local image = render_image(
        tostring(url),
        curr_win,
        curr_buf,
        x,
        y,
        height,
        not inline
      )
      if image ~= nil and inline and image.rendered_geometry.width then
        local image_width = image.rendered_geometry.width
        -- FIXME: filter images on the same line
        for _, o in ipairs(api.get_images()) do
          if
            o.rendered_geometry.y
            and o.rendered_geometry.y == image.rendered_geometry.x
          then
            o:clear()
            o:render()
          end
        end
        register_inline_images_autocmds(
          curr_buf,
          curr_win,
          image,
          x,
          y,
          image_width
        )
      end
    else
      Job:new({
        command = "node",
        args = { "index.js", tostring(url), colour, text },
        cwd = mathjax_dir,
        raw_args = true,
        on_exit = function(_result, _r)
          vim.schedule(function()
            local image = render_image(
              tostring(url),
              curr_win,
              curr_buf,
              x,
              y,
              height,
              not inline
            )
            if
              image ~= nil
              and inline
              and image.rendered_geometry.width ~= nil
            then
              local image_width = image.rendered_geometry.width
              register_inline_images_autocmds(
                curr_buf,
                curr_win,
                image,
                x,
                y,
                image_width
              )
            end
          end)
        end,
      }):start()
    end
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
  if latex_text:find("^$(.+)$$") then
    local inline_latex_text = latex_text:match("^$(.+)$$")
    create_job_and_render(
      inline_latex_text,
      con.color,
      range[2],
      range[1],
      1,
      true
    )
  else
    create_job_and_render(
      latex_text,
      con.color,
      range[2],
      range[4],
      height,
      false
    )
  end
end

-- FIXME: currently deletes thing that are not part of the refreshed buffer.
local function clear_all()
  for _, i in ipairs(api.get_images()) do
    i:clear()
  end

  for k, v in pairs(latex_images) do
    vim.api.nvim_del_autocmd(v.buf_enter_autocmd)
    if v.cursor_move_cmd ~= nil then
      vim.api.nvim_del_autocmd(v.cursor_move_cmd)
    end
    if v.inline_extmark ~= nil then
      vim.api.nvim_buf_del_extmark(0, mathjax_namespace, v.inline_extmark)
    end
    latex_images[k] = nil
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
		(latex_block _) @conceal (#set! conceal "")
		]]
  )
  local syntax_tree =
    vim.treesitter.get_parser(0, "markdown_inline", {}):parse()
  local root = syntax_tree[1]:root()

  clear_all()

  for _, match, _ in
    query_function:iter_matches(root, 0, nil, nil, { all = true })
  do
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
