---Helper function to parse argb
local api = vim.api

local bit = require "bit"
local tohex = bit.tohex

local min, max = math.min, math.max

local Trie = require "colorizer.trie"

local utils = require "colorizer.utils"
local byte_is_valid_colorchar = utils.byte_is_valid_colorchar

local parser = {}

local COLOR_MAP
local COLOR_TRIE
local COLOR_NAME_MINLEN, COLOR_NAME_MAXLEN
local COLOR_NAME_SETTINGS = { lowercase = true, strip_digits = false }
local TAILWIND_ENABLED = false
--- Grab all the colour values from `vim.api.nvim_get_color_map` and create a lookup table.
-- COLOR_MAP is used to store the colour values
---@param line string: Line to parse
---@param i number: Index of line from where to start parsing
---@param opts table: Currently contains whether tailwind is enabled or not
function parser.name_parser(line, i, opts)
  --- Setup the COLOR_MAP and COLOR_TRIE
  if not COLOR_TRIE or opts.tailwind ~= TAILWIND_ENABLED then
    COLOR_MAP = {}
    COLOR_TRIE = Trie()
    for k, v in pairs(api.nvim_get_color_map()) do
      if not (COLOR_NAME_SETTINGS.strip_digits and k:match "%d+$") then
        COLOR_NAME_MINLEN = COLOR_NAME_MINLEN and min(#k, COLOR_NAME_MINLEN) or #k
        COLOR_NAME_MAXLEN = COLOR_NAME_MAXLEN and max(#k, COLOR_NAME_MAXLEN) or #k
        local rgb_hex = tohex(v, 6)
        COLOR_MAP[k] = rgb_hex
        COLOR_TRIE:insert(k)
        if COLOR_NAME_SETTINGS.lowercase then
          local lowercase = k:lower()
          COLOR_MAP[lowercase] = rgb_hex
          COLOR_TRIE:insert(lowercase)
        end
      end
    end
    if opts and opts.tailwind then
      if opts.tailwind == true or opts.tailwind == "normal" or opts.tailwind == "both" then
        local tailwind = require "colorizer.tailwind_colors"
        -- setup tailwind colors
        for k, v in pairs(tailwind.colors) do
          for _, pre in ipairs(tailwind.prefixes) do
            local name = pre .. "-" .. k
            COLOR_NAME_MINLEN = COLOR_NAME_MINLEN and min(#name, COLOR_NAME_MINLEN) or #name
            COLOR_NAME_MAXLEN = COLOR_NAME_MAXLEN and max(#name, COLOR_NAME_MAXLEN) or #name
            COLOR_MAP[name] = v
            COLOR_TRIE:insert(name)
          end
        end
      end
    end

    TAILWIND_ENABLED = opts.tailwind
  end

  if opts and opts.custom then
    for k, v in pairs(opts.custom) do
      COLOR_NAME_MINLEN = COLOR_NAME_MINLEN and min(#k, COLOR_NAME_MINLEN) or #k
      COLOR_NAME_MAXLEN = COLOR_NAME_MAXLEN and max(#k, COLOR_NAME_MAXLEN) or #k
      COLOR_MAP[k] = string.sub(v, 2)
      COLOR_TRIE:insert(k)
    end
  end

  if #line < i + COLOR_NAME_MINLEN - 1 then
    return
  end

  if i > 1 and byte_is_valid_colorchar(line:byte(i - 1)) then
    return
  end

  local prefix = COLOR_TRIE:longest_prefix(line, i)
  if prefix then
    -- Check if there is a letter here so as to disallow matching here.
    -- Take the Blue out of Blueberry
    -- Line end or non-letter.
    local next_byte_index = i + #prefix
    if #line >= next_byte_index and byte_is_valid_colorchar(line:byte(next_byte_index)) then
      return
    end
    return #prefix, COLOR_MAP[prefix]
  end
end

return parser.name_parser
