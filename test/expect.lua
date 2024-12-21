-- Colorizer setup opts
local opts = {
  filetypes = {
    "*",
    "!dashboard",
    lua = {
      names = false,
      extra_names = {
        -- names = "#1F4770",
        names = "#791497",
        cool = "#3F3347",
        lua = "#107d3c",
        ["notcool"] = "#ee9240",
        redgreen = "#970000",
        asdf = "#234311",
        eeee = "#112238",
        -- lua
      },
      -- extra_names = function()
      --   local colors = require("kanagawa.colors").setup()
      --   return colors.palette
      -- end,
    },
  },
  buftypes = { "*", "!prompt", "!popup" },
  user_commands = true,
  user_default_options = {
    extra_names = {
      -- names = "#1F4770",
      names = "#1740F7",
      lua = "#7407F1",
    },
    names = true,
    RGB = true,
    RRGGBB = true,
    RRGGBBAA = true,
    AARRGGBB = true,
    rgb_fn = true,
    hsl_fn = true,
    css = true,
    css_fn = true,
    mode = "background",
    tailwind = true,
    sass = { enable = true, parsers = { css = true } },
    virtualtext = "■",
    virtualtext_inline = false,
    virtualtext_mode = "foreground",
    always_update = false,
  },
}

return opts

--[[ TEST CASES


0xFFFFFFF1 -- why does this highlight?

SUCCESS CASES:
CSS Named Colors:
olive -- do not remove
cyan magenta gold chartreuse lightgreen pink violet orange
lightcoral lightcyan lemonchiffon papayawhip peachpuff
blue gray lightblue gray100 white gold blue
Blue LightBlue Gray100 White
White

Extra names:
oniViolet oniViolet2 crystalBlue springViolet1 springViolet2 springBlue
lightBlue waveAqua2

Hexadecimal:
#RGB:
  #F0F
  #FFF #FFA #F0F #0FF #FF0
#RRGGBB:
  #FFFF00
  #FFFFFF #FFAA00 #FF00FF #00FFFF #FFFF99
#RRGGBBAA:
  #FFFFFFCC
  #FFFFAA99 #FF77FF99 #00FFFF88
0xRGB:
  0xF0F
  0xFFF 0xFFA 0xF0F 0x0FF 0xFF0
0xRRGGBB:
  0xFFFF00
  0xFFFFFF 0xFFAA00 0xFF00FF 0x00FFFF 0xFFFF99
0xRRGGBBAA:
  0xFFFFFFCC
  0xFFFFAA99 0xFF77FF99 0xFF3F3F88

0xFf32A14B 0xFf32A14B
0x1B29FB 0x1B29FB
0xF0F 0xF0F
0xA3B67CDE 0x7F12D9A5 0x7E43F2 0x34E8D3 0xB3A 0x1CD
#32a14b
#F0F #FF00FF #FFF00F8F #F0F #FF00FF
#FF32A14B
#FFF00F8F
#F0F #F00
#FF00FF #F00
#FFF00F8F #F00
#def
#deadbeef

RGB (standard and percentages):
rgb(    201     82.90   50 /0.5) rgb(   109, 100 ,      100, 0.8)
rgb(30% 20% 50%) rgb(0,0,0) rgb(255 122 127 / 80%)
rgb(255 122 127 / .7) rgba(200,30,0,1) rgba(200,30,0,0.5)
rgb(255, 200, 80)
rgb(255, 255, 255) rgb(255, 240, 200) rgb(240, 180, 120) rgb(80%, 60%, 40%)
rgb(255, 180, 180) rgb(255, 220, 120) rgb(255, 255, 100, 0.8)
rgb(255, 255, 255, 255)
rgb(255000, 255000, 255000, 255000)
rgb(100%, 100%, 100%)
rgb(100000%, 100000%, 100000%)

RGBA:
rgba(255, 240, 200, 0.5)
rgba(255, 255, 255, 1) rgba(255, 220, 180, 0.8) rgba(255, 200, 120, 0.4)
rgba(240, 180, 120, 0.6) rgba(255, 200, 80, 0.9) rgba(255, 180, 100, 0.7)
rgba(255, 255, 255, 1)
rgba(255000, 255000, 255000, 1000)

HSL:
hsl(300 50% 50%) hsl(300 50% 50% / 1) hsl(100 80% 50% / 0.4)
hsl(990 80% 50% / 0.4) hsl(720 80% 50% / 0.4)
hsl(1turn 80% 50% / 0.4) hsl(0.4turn 80% 50% / 0.4) hsl(1.4turn 80% 50% / 0.4)
hsl(60, 100%, 80%)
hsl(0, 100%, 90%) hsl(45, 100%, 70%) hsl(120, 100%, 85%) hsl(240, 100%, 85%)
hsl(300, 80%, 75%) hsl(180, 100%, 80%) hsl(210, 80%, 90%) hsl(90, 100%, 85%)
hsl(255, 100%, 100%)
hsl(10000, 10000%, 10000%)

HSLA:
hsla(300 50% 50%) hsla(300 50% 50% / 1)
hsla(300 50% 50% / 0.4) hsla(300,50%,50%,05)
hsla(360   ,  50%  ,  50%   ,  1.0000000000000001)
hsla(60, 100%, 85%, 0.5)
hsla(0, 100%, 90%, 1) hsla(120, 100%, 85%, 0.8) hsla(240, 100%, 85%, 0.7)
hsla(300, 80%, 75%, 0.6) hsla(180, 100%, 80%, 0.9) hsla(90, 100%, 85%, 0.4)
hsl(255, 100%, 100%, 1)
hsl(255000, 100000%, 100000%, 1000)

################################################################################

FAIL CASES:
matcher#add
Invalid Hexadecimal:
#F #FF #FFF0F #GGGGGG #F0FFF0F #F0FFF0FFF
0xGHI 0x1234 0xFFFFF
#FG0 #ZZZZZZ #12345 #FFFFF0F 0xGGG 0x12345 0xFFFFFG
0xf32A14B 0xf32A14B
0xB29FB 0xB29FB
0x0F 0x0F
0x3B67CDE 0xF12D9A5 0xE43F2 0x4E8D3 0x3A 0xCD
#---
#F0FF
#F0FFF
#F0FFF0F
#F0FFF0FFF
#define
#def0

Invalid CSS Named Colors:
ceruleanblue goldenrodlight brightcyan darkmagentapurple
Blueberry Gray1000 BlueGree BlueGray

Invalid RGB:
rgb(10, 1 00, 100) rgb(255, 255, 255, -1) rgb(10,,100) rgb()
rgb(256, 100, 100 rgb(-10, 100, 100) rgb(100, 100)
rgb(100,,100) -- causes error
rgb (10,255,100)
rgb(10, 1 00 ,  100)

Invalid RGBA:
rgba(10, 100) rgba(-10, 0, 255, 0.2)
rgba(100, 100, 100, -0.5)
rgba(100, 100) rgba(255, , 255, 0.5)

Invalid HSL:
hsl(300 50% 50 / 1) hsl(30, 50%, 20%,) hsl()
hsl(300, 50, 50) hsl(300,,50%) hsl(300, 50%,)
hsl(300 50% 50% 1)
hsl(300 50% 50 / 1)

Invalid HSLA:
hsla(120, 50%, 50, -0.1) hsla(300, 50) hsla(30, 100%, 50% 1) hsla()
hsla(300, 50%, 50%, -0.5)
hsla(300, 50, 50%, 0.5) hsla(300, 50%,) hsla(300, 50%, 50% 0.5)
hsla(, 50%, 50%, 0.5)
hsla(10 10% 10% 1)
hsla(300,50%,50,1.0000000000000001)
hsla(300,50,50,1.0000000000000001)
hsla(361,50,50,1.0000000000000001)
]]