-- Moondeck Color Utilities
-- Delegates to native Rust implementations for performance

local Color = {}

function Color.blend(bg, fg, opacity)
  return util.color_blend(bg, fg, opacity)
end

function Color.luminance(hex)
  return util.color_luminance(hex)
end

-- Keep mix as alias for blend (same operation)
Color.mix = Color.blend

return Color
