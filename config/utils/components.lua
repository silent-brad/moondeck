-- Moondeck Component Library

local color_util = require("utils.color")

local Components = {}

-- Card component: rounded rectangle with shadow, transparency, and border
-- opts (all optional):
--   opacity   - card background opacity 0..1 (default 0.7)
--   shadow    - shadow size in layers (default 3, 0 to disable)
--   shadow_opacity - base shadow opacity per layer (default 0.08)
function Components.card(gfx, x, y, w, h, opts)
  if not gfx then
    return
  end

  opts = opts or {}
  local th = theme:get()

  local bg_page = th.bg_primary
  local bg_card = th.bg_card
  local radius = th.card_radius or 12
  local border = th.border_primary
  local border_width = th.border_width or 1
  local opacity = opts.opacity or 0.7
  local shadow_layers = opts.shadow or 3
  local shadow_opacity = opts.shadow_opacity or 0.08

  -- Draw shadow layers (larger rects behind the card, blended toward bg)
  if shadow_layers > 0 and gfx.fill_rounded_rect then
    local shadow_color = color_util.luminance(bg_page) < 0.3 and "#ffffff" or "#000000"
    for i = shadow_layers, 1, -1 do
      local sc = color_util.blend(bg_page, shadow_color, shadow_opacity * i)
      gfx:fill_rounded_rect(x + i, y + i, w + i * 2, h + i * 2, radius + i, sc)
    end
  end

  -- Draw card background (blended with page background for fake transparency)
  if gfx.fill_rounded_rect then
    local blended = color_util.blend(bg_page, bg_card, opacity)
    gfx:fill_rounded_rect(x, y, w, h, radius, blended)
  end

  -- Draw border
  if gfx.stroke_rounded_rect then
    gfx:stroke_rounded_rect(x, y, w, h, radius, border, border_width)
  end
end

-- Title bar component
function Components.title_bar(gfx, x, y, w, title, opts)
  opts = opts or {}
  local th = theme:get()

  local color = opts.color or th.text_secondary
  local accent = opts.accent or th.accent_primary
  local font_family = opts.font_family or "ebgaramond"
  local font_size = opts.font_size or 32
  local show_line = opts.show_line ~= false

  -- Draw title
  if gfx.text then
    gfx:text(x, y, title, color, font_family, font_size)
  end

  -- Draw accent line
  if show_line and gfx.line then
    local line_y = y + 36
    gfx:line(x, line_y, x + w, line_y, accent, 2)
  end

  return 34 -- Return height consumed
end

-- Value display: large number with label
function Components.value_display(gfx, x, y, value, label, opts)
  opts = opts or {}
  local th = theme:get()

  local value_color = opts.value_color or th.text_secondary
  local label_color = opts.label_color or th.text_muted
  local value_font_family = opts.value_font_family or "inter"
  local value_font_size = opts.value_font_size or 32
  local label_font_family = opts.label_font_family or "inter"
  local label_font_size = opts.label_font_size or 12
  local unit = opts.unit or ""

  -- Draw value
  gfx:text(x, y, tostring(value) .. unit, value_color, value_font_family, value_font_size)

  -- Draw label below
  if label then
    gfx:text(x, y + 28, label, label_color, label_font_family, label_font_size)
  end

  return 45 -- Return height consumed
end

-- Item row: icon/indicator + label + value
function Components.item_row(gfx, x, y, w, label, value, opts)
  opts = opts or {}
  local th = theme:get()

  local label_color = opts.label_color or th.text_muted
  local value_color = opts.value_color or th.text_secondary
  local indicator_color = opts.indicator or nil
  local font_family = opts.font_family or "inter"
  local font_size = opts.font_size or 16

  local text_x = x

  -- Draw indicator dot if specified
  if indicator_color then
    gfx:fill_circle(x + 4, y + 6, 4, indicator_color)
    text_x = x + 16
  end

  -- Draw label
  gfx:text(text_x, y, label, label_color, font_family, font_size)

  -- Draw value (right-aligned)
  local value_str = tostring(value)
  local value_width = #value_str * 8 -- Approximate
  gfx:text(x + w - value_width, y, value_str, value_color, font_family, font_size)

  return 20 -- Return height consumed
end

-- Divider line
function Components.divider(gfx, x, y, w, opts)
  opts = opts or {}
  local th = theme:get()

  local color = opts.color or th.border_primary
  local thickness = opts.thickness or 1

  gfx:line(x, y, x + w, y, color, thickness)

  return thickness + 8 -- Return height consumed with padding
end

-- Progress bar
function Components.progress_bar(gfx, x, y, w, h, progress, opts)
  opts = opts or {}
  local th = theme:get()

  local bg = opts.bg or th.bg_tertiary
  local fg = opts.fg or th.accent_primary
  local radius = opts.radius or (h / 2)

  -- Clamp progress to 0-1
  progress = math.max(0, math.min(1, progress))

  -- Draw background
  gfx:fill_rounded_rect(x, y, w, h, radius, bg)

  -- Draw fill
  if progress > 0 then
    local fill_w = math.max(h, w * progress)
    gfx:fill_rounded_rect(x, y, fill_w, h, radius, fg)
  end

  return h + 8 -- Return height consumed
end

-- Status indicator (dot + text)
function Components.status(gfx, x, y, text, status, opts)
  opts = opts or {}
  local th = theme:get()

  local colors = {
    ok = th.accent_success,
    warning = th.accent_warning,
    error = th.accent_error,
    info = th.accent_primary,
  }

  local dot_color = colors[status] or th.text_muted
  local text_color = opts.text_color or th.text_secondary
  local font_family = opts.font_family or "inter"
  local font_size = opts.font_size or 12

  -- Draw status dot
  gfx:fill_circle(x + 4, y + 5, 4, dot_color)

  -- Draw text
  gfx:text(x + 14, y, text, text_color, font_family, font_size)

  return 16 -- Return height consumed
end

-- Mini chart (sparkline)
function Components.sparkline(gfx, x, y, w, h, data, opts)
  opts = opts or {}
  local th = theme:get()

  local color = opts.color or th.accent_primary
  local thickness = opts.thickness or 2

  if not data or #data < 2 then
    return h
  end

  -- Find min/max for scaling
  local min_val, max_val = data[1], data[1]
  for _, v in ipairs(data) do
    if v < min_val then
      min_val = v
    end
    if v > max_val then
      max_val = v
    end
  end

  local range = max_val - min_val
  if range == 0 then
    range = 1
  end

  -- Draw lines
  local step = w / (#data - 1)
  for i = 1, #data - 1 do
    local x1 = x + (i - 1) * step
    local y1 = y + h - ((data[i] - min_val) / range * h)
    local x2 = x + i * step
    local y2 = y + h - ((data[i + 1] - min_val) / range * h)

    gfx:line(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2), color, thickness)
  end

  return h
end

-- Icon placeholder (circle with letter)
function Components.icon(gfx, x, y, size, letter, opts)
  opts = opts or {}
  local th = theme:get()

  local bg = opts.bg or th.accent_primary
  local fg = opts.fg or th.bg_primary

  local radius = size / 2
  gfx:fill_circle(x + radius, y + radius, radius, bg)
  gfx:text(x + radius - 4, y + radius - 6, letter, fg, "inter", 16)

  return size
end

-- Compact line graph with optional axes, labels, grid, and area fill
-- data: array of numbers OR array of {x, y} points
-- opts:
--   color         - line color (default: accent_primary)
--   thickness     - line thickness (default: 2)
--   grid_color    - grid line color (default: border_primary)
--   label_color   - axis label color (default: text_muted)
--   show_grid     - show horizontal grid lines (default: false)
--   show_y_labels - show Y-axis value labels (default: false)
--   y_label_fmt   - format string for y-axis labels (default: "%.0f")
--   grid_lines    - number of horizontal grid lines (default: 3)
--   fill          - fill area under the line (default: false)
--   fill_color    - fill color (default: blended line color)
function Components.line_graph(gfx, x, y, w, h, data, opts)
  opts = opts or {}
  local th = theme:get()

  local color = opts.color or th.accent_primary
  local thickness = opts.thickness or 2
  local grid_color = opts.grid_color or th.border_primary
  local label_color = opts.label_color or th.text_muted
  local show_grid = opts.show_grid or false
  local show_y_labels = opts.show_y_labels or false
  local y_label_fmt = opts.y_label_fmt or "%.0f"
  local grid_lines = opts.grid_lines or 3
  local do_fill = opts.fill or false
  local fill_color = opts.fill_color or color_util.blend(th.bg_card, color, 0.25)

  if not data or #data < 2 then
    return h
  end

  -- Normalize data: accept plain number arrays or {x, y} tables
  local values = {}
  for i = 1, #data do
    if type(data[i]) == "table" then
      values[i] = data[i].y
    else
      values[i] = data[i]
    end
  end

  -- Reserve space for labels only when shown
  local label_w = show_y_labels and 40 or 0
  local graph_x = x + label_w
  local graph_w = w - label_w
  local graph_h = h

  -- Find min/max
  local min_y, max_y = values[1], values[1]
  for i = 2, #values do
    if values[i] < min_y then
      min_y = values[i]
    end
    if values[i] > max_y then
      max_y = values[i]
    end
  end

  local range = max_y - min_y
  if range == 0 then
    range = 1
  end
  local padding = range * 0.05
  min_y = min_y - padding
  max_y = max_y + padding
  range = max_y - min_y

  -- Draw grid lines and optional Y labels
  if show_grid then
    for i = 0, grid_lines do
      local gy = y + graph_h - (i / grid_lines) * graph_h
      gfx:line(graph_x, math.floor(gy), graph_x + graph_w, math.floor(gy), grid_color, 1)
      if show_y_labels then
        local val = min_y + (i / grid_lines) * range
        gfx:text(x, math.floor(gy) - 5, util.format(y_label_fmt, val), label_color, "inter", 10)
      end
    end
  end

  -- Precompute Y positions
  local step = graph_w / (#values - 1)
  local y_positions = {}
  for i = 1, #values do
    y_positions[i] = y + graph_h - ((values[i] - min_y) / range * graph_h)
  end

  -- Draw area fill (sweep every pixel column, interpolating between points)
  if do_fill then
    local base_y = y + graph_h
    local first_px = math.floor(graph_x)
    local last_px = math.floor(graph_x + (#values - 1) * step)
    for px = first_px, last_px do
      local frac = (px - graph_x) / step
      local idx = math.floor(frac) + 1
      if idx < 1 then
        idx = 1
      end
      if idx >= #values then
        idx = #values - 1
      end
      local t = frac - (idx - 1)
      local py = math.floor(y_positions[idx] + (y_positions[idx + 1] - y_positions[idx]) * t)
      if py < base_y then
        gfx:line(px, py, px, base_y, fill_color, 1)
      end
    end
  end

  -- Draw data line
  for i = 1, #values - 1 do
    local x1 = graph_x + (i - 1) * step
    local x2 = graph_x + i * step
    gfx:line(
      math.floor(x1),
      math.floor(y_positions[i]),
      math.floor(x2),
      math.floor(y_positions[i + 1]),
      color,
      thickness
    )
  end

  return h
end

-- Loading indicator
function Components.loading(gfx, x, y, text)
  local th = theme:get()
  text = text or "Loading..."
  gfx:text(x, y, text, th.text_muted, "inter", 16)
  return 20
end

-- Error display
function Components.error(gfx, x, y, w, message)
  local th = theme:get()
  gfx:text(x, y, "Error", th.accent_error, "inter", 16)
  gfx:text(x, y + 18, message or "Unknown error", th.text_muted, "inter", 12)
  return 40
end

return Components
