-- Moondeck Color Utilities
-- Hex color parsing and blending for fake transparency on RGB565

local Color = {}

-- stylua: ignore
local hex_digits = {
  ["0"] = 0, ["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4,
  ["5"] = 5, ["6"] = 6, ["7"] = 7, ["8"] = 8, ["9"] = 9,
  ["a"] = 10, ["b"] = 11, ["c"] = 12, ["d"] = 13, ["e"] = 14, ["f"] = 15,
  ["A"] = 10, ["B"] = 11, ["C"] = 12, ["D"] = 13, ["E"] = 14, ["F"] = 15,
}

local function hex2(s, pos)
  local hi = hex_digits[string.sub(s, pos, pos)] or 0
  local lo = hex_digits[string.sub(s, pos + 1, pos + 1)] or 0
  return hi * 16 + lo
end

-- Parse "#rrggbb" to {r, g, b}
function Color.parse(hex)
  return { hex2(hex, 2), hex2(hex, 4), hex2(hex, 6) }
end

-- Convert {r, g, b} to packed integer (for gfx calls)
function Color.to_int(rgb)
  return rgb[1] * 65536 + rgb[2] * 256 + rgb[3]
end

-- Linearly interpolate between two hex colors at ratio t (0..1)
-- Returns a packed integer color
function Color.mix(c1, c2, t)
  local a = Color.parse(c1)
  local b = Color.parse(c2)
  return Color.to_int({
    math.floor(a[1] + (b[1] - a[1]) * t),
    math.floor(a[2] + (b[2] - a[2]) * t),
    math.floor(a[3] + (b[3] - a[3]) * t),
  })
end

-- Perceived luminance of a hex color (0..1)
function Color.luminance(hex)
  local rgb = Color.parse(hex)
  return (0.299 * rgb[1] + 0.587 * rgb[2] + 0.114 * rgb[3]) / 255
end

-- Blend a foreground hex color over a background hex color at given opacity (0..1)
-- Equivalent to true alpha compositing on a solid background
function Color.blend(bg, fg, opacity)
  return Color.mix(bg, fg, opacity)
end

return Color
