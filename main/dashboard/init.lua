--[[
Moondeck - Main Entry
--]]

local dashboard = {}

dashboard.cfg = nil
dashboard.components = {}

function dashboard.init()
	display.init()

	dashboard.cfg = {
		width = 800,
		height = 480,
		header_height = 30,
		refresh_interval = 300,
	}

	dashboard.cfg.width, dashboard.cfg.height = display.size()

	dashboard.theme = {
		bg_primary = display.BLACK,
		bg_secondary = display.rgb(8, 8, 16),
		accent_cyan = display.CYAN,
		accent_magenta = display.rgb(255, 0, 255),
		accent_yellow = display.YELLOW,
		accent_orange = display.rgb(255, 165, 0),
		text_primary = display.WHITE,
		text_secondary = display.rgb(192, 192, 192),
		border = display.rgb(0, 80, 100),
		glow = display.rgb(0, 40, 80),
	}

	dashboard.panels = {
		weather = { x = 10, y = 40, w = 250, h = 200 },
		btc = { x = 270, y = 40, w = 250, h = 200 },
		verse = { x = 10, y = 250, w = 780, h = 220 },
	}

	return true
end

function dashboard.clear()
	display.clear(dashboard.theme.bg_primary)
end

function dashboard.draw_header(title)
	local t = dashboard.theme
	local cfg = dashboard.cfg

	display.rect(0, 0, cfg.width, cfg.header_height, t.bg_secondary, true)
	display.line(0, cfg.header_height, cfg.width, cfg.header_height, t.accent_cyan)
	display.line(0, cfg.header_height + 1, cfg.width, cfg.header_height + 1, t.glow)

	local title_x = math.floor((cfg.width - #title * 8) / 2)
	display.text_font(title_x, 8, title, t.accent_cyan, display.FONT_GARAMOND_20)

	local time_str = os.date("%H:%M")
	display.text_font(cfg.width - 60, 8, time_str, t.text_secondary, display.FONT_INTER_20)
end

function dashboard.draw_panel(panel, title, content_fn)
	local t = dashboard.theme
	local p = panel

	display.rect(p.x, p.y, p.w, p.h, t.bg_secondary, true)

	display.rect(p.x, p.y, p.w, p.h, t.border, false)
	display.line(p.x, p.y, p.x + p.w, p.y, t.accent_cyan)
	display.line(p.x, p.y, p.x, p.y + p.h, t.accent_cyan)

	display.rect(p.x + 5, p.y + 2, #title * 10 + 10, 22, t.bg_secondary, true)
	display.text_font(p.x + 10, p.y + 5, title, t.accent_magenta, display.FONT_GARAMOND_20)

	if content_fn then
		content_fn(math.floor(p.x + 10), math.floor(p.y + 25), math.floor(p.w - 20), math.floor(p.h - 35))
	end
end

function dashboard.draw_scanlines()
	local t = dashboard.theme
	local cfg = dashboard.cfg

	for y = 0, cfg.height - 1, 4 do
		display.line(0, y, cfg.width, y, display.rgb(0, 0, 0))
	end
end

function dashboard.glitch_effect(x, y, w, h)
	local t = dashboard.theme

	for i = 1, 3 do
		local gy = y + math.random(0, h)
		local gw = math.random(10, 50)
		display.line(x, gy, x + gw, gy, t.accent_cyan)
	end
end

return dashboard
