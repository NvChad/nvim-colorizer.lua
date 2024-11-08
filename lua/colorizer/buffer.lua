--@module colorizer.buffer
local M = {}

local color = require("colorizer.color")
local make_matcher = require("colorizer.matcher").make
local sass = require("colorizer.sass")
local tailwind = require("colorizer.tailwind")

local HIGHLIGHT_NAME_PREFIX = "colorizer"
local HIGHLIGHT_CACHE = {}

--- Default namespace used in `highlight` and `colorizer.attach_to_buffer`.
---@see highlight
---@see colorizer.attach_to_buffer
M.default_namespace = vim.api.nvim_create_namespace("colorizer")

--- Highlight mode which will be use to render the colour
M.highlight_mode_names = {
  background = "mb",
  foreground = "mf",
  virtualtext = "mv",
}

--- Clean the highlight cache
function M.clear_hl_cache()
  HIGHLIGHT_CACHE = {}
end

--- Make a deterministic name for a highlight given these attributes
local function make_highlight_name(rgb, mode)
  return table.concat({ HIGHLIGHT_NAME_PREFIX, M.highlight_mode_names[mode], rgb }, "_")
end

local function create_highlight(rgb_hex, mode)
  mode = mode or "background"
  -- TODO validate rgb format?
  rgb_hex = rgb_hex:lower()
  local cache_key = table.concat({ M.highlight_mode_names[mode], rgb_hex }, "_")
  local highlight_name = HIGHLIGHT_CACHE[cache_key]

  -- Look up in our cache.
  if highlight_name then
    return highlight_name
  end

  -- convert from #fff to #ffffff
  if #rgb_hex == 3 then
    rgb_hex = table.concat({
      rgb_hex:sub(1, 1):rep(2),
      rgb_hex:sub(2, 2):rep(2),
      rgb_hex:sub(3, 3):rep(2),
    })
  end

  -- Create the highlight
  highlight_name = make_highlight_name(rgb_hex, mode)
  if mode == "foreground" then
    vim.api.nvim_set_hl(0, highlight_name, { fg = "#" .. rgb_hex })
  else
    local rr, gg, bb = rgb_hex:sub(1, 2), rgb_hex:sub(3, 4), rgb_hex:sub(5, 6)
    local r, g, b = tonumber(rr, 16), tonumber(gg, 16), tonumber(bb, 16)
    local fg_color
    if color.is_bright(r, g, b) then
      fg_color = "Black"
    else
      fg_color = "White"
    end
    vim.api.nvim_set_hl(0, highlight_name, { fg = fg_color, bg = "#" .. rgb_hex })
  end
  HIGHLIGHT_CACHE[cache_key] = highlight_name
  return highlight_name
end

--- Create highlight and set highlights
---@param bufnr number: buffer number (0 for current)
---@param ns_id number
---@param line_start number
---@param line_end number
---@param data table: table output of `parse_lines`
---@param options table: Passed in setup, mainly for `user_default_options`
function M.add_highlight(bufnr, ns_id, line_start, line_end, data, options)
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, line_start, line_end)

  local mode = options.mode == "background" and "background" or "foreground"
  if vim.tbl_contains({ "foreground", "background" }, options.mode) then
    for linenr, hls in pairs(data) do
      for _, hl in ipairs(hls) do
        local hlname = create_highlight(hl.rgb_hex, mode)
        vim.api.nvim_buf_add_highlight(bufnr, ns_id, hlname, linenr, hl.range[1], hl.range[2])
      end
    end
  elseif options.mode == "virtualtext" then
    for linenr, hls in pairs(data) do
      for _, hl in ipairs(hls) do
        local hlname = create_highlight(hl.rgb_hex, mode)

        local start_col = hl.range[2]
        local opts = {
          virt_text = { { options.virtualtext or "■", hlname } },
          hl_mode = "combine",
          priority = 0,
        }

        if options.virtualtext_inline then
          start_col = hl.range[1]
          opts.virt_text_pos = "inline"
          opts.virt_text = { { (options.virtualtext or "■") .. " ", hlname } }
        end

        opts.end_col = start_col

        vim.api.nvim_buf_set_extmark(bufnr, ns_id, linenr, start_col, opts)
      end
    end
  end
end

--- Highlight the buffer region.
-- Highlight starting from `line_start` (0-indexed) for each line described by `lines` in the
-- buffer id `bufnr` and attach it to the namespace id `ns_id`.
---@param bufnr number: buffer number (0 for current)
---@param ns_id number: namespace id.  default is "colorizer", created with vim.api.nvim_create_namespace
---@param line_start number: line_start should be 0-indexed
---@param line_end number: Last line to highlight
---@param options table: Configuration options as described in `setup`
---@param options_local table: Buffer local variables
---@return nil|boolean|number,table
function M.highlight(bufnr, ns_id, line_start, line_end, options, options_local)
  local returns = { detach = { ns_id = {}, functions = {} } }
  if bufnr == 0 or bufnr == nil then
    bufnr = vim.api.nvim_get_current_buf()
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, line_start, line_end, false)

  ns_id = ns_id or M.default_namespace

  -- only update sass varibles when text is changed
  if options_local.__event ~= "WinScrolled" and options.sass and options.sass.enable then
    table.insert(returns.detach.functions, sass.cleanup)
    sass.update_variables(
      bufnr,
      0,
      -1,
      nil,
      make_matcher(options.sass.parsers),
      options,
      options_local
    )
  end

  local data = M.parse_lines(bufnr, lines, line_start, options) or {}
  M.add_highlight(bufnr, ns_id, line_start, line_end, data, options)

  if options.tailwind == "lsp" or options.tailwind == "both" then
    tailwind.setup_lsp_colors(bufnr, options, options_local, M.add_highlight)
    table.insert(returns.detach.functions, tailwind.cleanup)
  end

  return true, returns
end

--- Parse the given lines for colors and return a table containing
-- rgb_hex and range per line
---@param bufnr number: buffer number (0 for current)
---@param lines table: table of lines to parse
---@param line_start number: This is the buffer line number, from where to start highlighting
---@param options table: Passed in `colorizer.setup`, Only uses `user_default_options`
---@return table|nil
function M.parse_lines(bufnr, lines, line_start, options)
  local loop_parse_fn = make_matcher(options)
  if not loop_parse_fn then
    return
  end

  local data = {}
  for current_linenum, line in ipairs(lines) do
    current_linenum = current_linenum - 1 + line_start
    data[current_linenum] = data[current_linenum] or {}

    -- Upvalues are options and current_linenum
    local i = 1
    while i < #line do
      local length, rgb_hex = loop_parse_fn(line, i, bufnr)
      if length and rgb_hex then
        table.insert(
          data[current_linenum],
          { rgb_hex = rgb_hex, range = { i - 1, i + length - 1 } }
        )
        i = i + length
      else
        i = i + 1
      end
    end
  end

  return data
end

-- gets used in rehighlight function only
local BUFFER_LINES = {}
-- get the amount lines to highlight
local function getrow(bufnr)
  BUFFER_LINES[bufnr] = BUFFER_LINES[bufnr] or {}

  local a = vim.api.nvim_buf_call(bufnr, function()
    return {
      vim.fn.line("w0"),
      vim.fn.line("w$"),
    }
  end)
  local min, max
  local new_min, new_max = a[1] - 1, a[2]
  local old_min, old_max = BUFFER_LINES[bufnr]["min"], BUFFER_LINES[bufnr]["max"]

  if old_min and old_max then
    -- Triggered for TextChanged autocmds
    -- TODO: Find a way to just apply highlight to changed text lines
    if (old_max == new_max) or (old_min == new_min) then
      min, max = new_min, new_max
    -- Triggered for WinScrolled autocmd - Scroll Down
    elseif old_max < new_max then
      min = old_max
      max = new_max
    -- Triggered for WinScrolled autocmd - Scroll Up
    elseif old_max > new_max then
      min = new_min
      max = new_min + (old_max - new_max)
    end
    -- just in case a long jump was made
    if max - min > new_max - new_min then
      min = new_min
      max = new_max
    end
  end
  min = min or new_min
  max = max or new_max
  -- store current window position to be used later to incremently highlight
  BUFFER_LINES[bufnr]["max"] = new_max
  BUFFER_LINES[bufnr]["min"] = new_min
  return min, max
end

--- Rehighlight the buffer if colorizer is active
---@param bufnr number: buffer number (0 for current)
---@param options table: Buffer options
---@param options_local table|nil: Buffer local variables
---@param use_local_lines boolean|nil Whether to use lines num range from options_local
---@return nil|boolean|number,table
function M.rehighlight(bufnr, options, options_local, use_local_lines)
  bufnr = (bufnr == 0 or not bufnr) and vim.api.nvim_get_current_buf() or bufnr

  local ns_id = M.default_namespace

  local min, max
  if use_local_lines and options_local then
    min, max = options_local.__startline or 0, options_local.__endline or -1
  else
    min, max = getrow(bufnr)
  end

  local bool, returns = M.highlight(bufnr, ns_id, min, max, options, options_local or {})
  table.insert(returns.detach.functions, function()
    BUFFER_LINES[bufnr] = nil
  end)

  return bool, returns
end

return M
