--[[
Moondeck Application
Main application loop with screen management and touch handling
--]]

local app = {}

local config = nil
local screens_config = nil
local theme = nil
local layout = nil
local screen_manager = nil
local touch_handler = nil
local plugins_manager = nil
local ui = nil

app.running = false
app.last_refresh = 0
app.refresh_interval = 300

function app.load_config()
	local ok, cfg = pcall(require, "config")
	if ok then
		config = cfg
		app.refresh_interval = config.display and config.display.refresh_interval or 300
	else
		print("Failed to load config: " .. tostring(cfg))
		return false
	end

	ok, screens_config = pcall(require, "config.screens")
	if not ok then
		print("Failed to load screens config: " .. tostring(screens_config))
		screens_config = nil
	end

	local theme_name = config.theme or "cyberpunk"
	ok, theme = pcall(require, "config.themes." .. theme_name)
	if not ok then
		print("Failed to load theme: " .. tostring(theme))
		theme = nil
	end

	local layout_name = config.layout or "default"
	ok, layout = pcall(require, "config.layouts." .. layout_name)
	if not ok then
		print("Failed to load layout: " .. tostring(layout))
		layout = nil
	end

	return true
end

function app.load_modules()
	local ok

	ok, ui = pcall(require, "ui")
	if not ok then
		print("Failed to load ui: " .. tostring(ui))
		ui = nil
	end

	ok, plugins_manager = pcall(require, "plugins")
	if not ok then
		print("Failed to load plugins: " .. tostring(plugins_manager))
		plugins_manager = nil
	else
		print("Plugins module loaded")
	end

	ok, screen_manager = pcall(require, "screen_manager")
	if not ok then
		print("Failed to load screen_manager: " .. tostring(screen_manager))
		screen_manager = nil
	end

	ok, touch_handler = pcall(require, "touch.handler")
	if not ok then
		print("Failed to load touch.handler: " .. tostring(touch_handler))
		touch_handler = nil
	end

	return true
end

function app.init()
	print("Initializing Moondeck...")

	if not app.load_config() then
		print("Config load failed, using defaults")
	end

	app.load_modules()

	if screen_manager and screens_config then
		screen_manager.init(screens_config)
	end

	if touch_handler then
		touch_handler.init()
	end

	if plugins_manager and config then
		plugins_manager.init(config)
	end

	return true
end

function app.connect_wifi()
	if not wifi then
		print("WiFi module not available")
		return false
	end

	if not config or not config.wifi then
		print("WiFi config not loaded")
		return false
	end

	print("Connecting to WiFi: " .. config.wifi.ssid)
	local ok = wifi.connect(config.wifi.ssid, config.wifi.password)

	if ok then
		print("WiFi connected!")
		local ip = wifi.get_ip()
		if ip then
			print("IP Address: " .. ip)
		end
		return true
	else
		print("WiFi connection failed")
		return false
	end
end

function app.fetch_data()
	print("Fetching data...")
	if plugins_manager then
		plugins_manager.fetch_all()
	end
	app.last_refresh = os.time()
	print("Data fetch complete")
end

function app.draw_current_screen()
	if not screen_manager or not theme then
		return
	end

	local screen = screen_manager.get_current()
	if not screen then
		return
	end

	-- Clear display
	display.clear(theme.colors.bg_primary)

	-- Draw header
	app.draw_header(screen.name:upper())

	-- Get layout for this screen
	local screen_layout = layout
	if screen.layout then
		local ok, l = pcall(require, "config.layouts." .. screen.layout)
		if ok then
			screen_layout = l
		end
	end

	-- Draw widgets in slots
	if screen.widgets and screen_layout and plugins_manager then
		for _, widget in ipairs(screen.widgets) do
			local slot = screen_layout.slots[widget.slot]
			if slot then
				app.draw_widget_panel(widget.name, slot)
			end
		end
	end

	-- Draw screen indicator
	app.draw_screen_indicator()

	-- Draw status bar
	app.draw_status_bar()
end

function app.draw_header(title)
	if not theme then
		return
	end
	local t = theme.colors
	local width = config and config.display and config.display.width or 800

	display.rect(0, 0, width, 30, t.bg_secondary, true)
	display.line(0, 30, width, 30, t.border)
	display.text_font(10, 5, title, t.accent_primary, display.FONT_GARAMOND_20)

	-- Time on right
	local time_str = os.date("%H:%M")
	display.text_font(width - 60, 5, time_str, t.text_primary, display.FONT_INTER_20)
end

function app.draw_widget_panel(plugin_name, slot)
	if not theme or not plugins_manager then
		return
	end
	local t = theme.colors

	-- Draw panel background
	display.rect(slot.x, slot.y, slot.width, slot.height, t.bg_panel, true)
	display.rect(slot.x, slot.y, slot.width, slot.height, t.border, false)

	-- Draw plugin title
	local title = plugin_name:upper()
	local title_w = #title * 10 + 10
	display.rect(slot.x + 5, slot.y - 2, title_w, 20, t.bg_panel, true)
	display.text_font(slot.x + 10, slot.y + 2, title, t.accent_secondary, display.FONT_INTER_20)

	-- Render plugin content
	local content_y = slot.y + 25
	local content_h = slot.height - 30
	plugins_manager.render_slot(plugin_name, slot.x + 10, content_y, slot.width - 20, content_h, theme, slot.size)
end

function app.draw_screen_indicator()
	if not screen_manager or not theme then
		return
	end

	local total = screen_manager.get_screen_count()
	local current = screen_manager.get_current_index()
	local width = config and config.display and config.display.width or 800
	local height = config and config.display and config.display.height or 480

	local dot_size = 8
	local dot_gap = 12
	local total_w = (dot_size * total) + (dot_gap * (total - 1))
	local start_x = (width - total_w) / 2
	local y = height - 35

	for i = 1, total do
		local x = start_x + (i - 1) * (dot_size + dot_gap)
		local color = (i == current) and theme.colors.accent_primary or theme.colors.text_muted
		display.fill_circle(math.floor(x + dot_size / 2), math.floor(y), math.floor(dot_size / 2), color)
	end
end

function app.draw_status_bar()
	if not theme or not config then
		return
	end
	local t = theme.colors
	local width = config.display and config.display.width or 800
	local height = config.display and config.display.height or 480
	local y = height - 18

	display.rect(0, y - 2, width, 20, t.bg_secondary, true)
	display.line(0, y - 2, width, y - 2, t.border)

	-- WiFi status
	local wifi_status = "WiFi: --"
	local wifi_color = t.text_secondary
	if wifi then
		if wifi.is_connected() then
			wifi_status = "WiFi: OK"
			wifi_color = t.accent_success
		else
			wifi_status = "WiFi: X"
			wifi_color = t.accent_error
		end
	end
	display.text_font(5, y, wifi_status, wifi_color, display.FONT_DEFAULT)

	-- Next refresh
	local next_refresh = app.refresh_interval - (os.time() - app.last_refresh)
	if next_refresh < 0 then
		next_refresh = 0
	end
	local refresh_str = string.format("Next: %ds", math.floor(next_refresh))
	display.text_font(width - 100, y, refresh_str, t.text_muted, display.FONT_DEFAULT)

	-- Memory
	local mem = collectgarbage("count")
	local mem_str = string.format("%.1fKB", mem)
	display.text_font(math.floor(width / 2 - 30), y, mem_str, t.text_muted, display.FONT_DEFAULT)
end

function app.handle_touch(event_type, x, y)
	if touch_handler then
		touch_handler.process_touch(event_type, x, y)
		-- Redraw if screen changed
		app.draw_current_screen()
	end
end

function app.draw_splash()
	local bg = 0x0000
	local cyan = 0x07FF
	local magenta = 0xF81F
	local yellow = 0xFFE0
	local gray = 0x8410

	display.clear(bg)

	local cx, cy = 400, 240

	display.rect(cx - 200, cy - 80, 400, 160, 0x0841, true)
	display.rect(cx - 200, cy - 80, 400, 160, cyan, false)

	display.text_font(cx - 80, cy - 30, "MOONDECK", cyan, display.FONT_GARAMOND_20)
	display.text_font(cx - 120, cy, "CYBERPUNK DASHBOARD", magenta, display.FONT_GARAMOND_20)
	display.text_font(cx - 30, cy + 30, "v1.0.0", gray, display.FONT_INTER_20)
	display.text_font(cx - 60, cy + 55, "Connecting...", yellow, display.FONT_INTER_20)
end

function app.run()
	if not app.init() then
		print("App initialization failed")
		return
	end

	app.running = true
	app.draw_splash()

	-- Initialize touch
	if touch then
		local ok = touch.init()
		if ok then
			print("Touch initialized")
		else
			print("Touch init failed")
		end
	end

	local wifi_ok = app.connect_wifi()
	if wifi_ok then
		app.fetch_data()
	end

	app.draw_current_screen()
	print("Dashboard running. Refresh interval: " .. app.refresh_interval .. "s")

	local touch_state = "idle"
	local touch_start_x, touch_start_y = 0, 0
	local last_refresh_check = os.time()

	while app.running do
		-- Poll touch at ~30Hz
		sys.sleep(33)

		-- Handle touch
		if touch then
			local x, y, touched = touch.read()
			if touched then
				if touch_state == "idle" then
					touch_state = "pressed"
					touch_start_x, touch_start_y = x, y
				end
			else
				if touch_state == "pressed" then
					touch_state = "idle"
					-- Check for swipe
					local dx = x - touch_start_x
					local dy = y - touch_start_y
					local dist = math.sqrt(dx * dx + dy * dy)

					if dist > 80 then
						if math.abs(dx) > math.abs(dy) then
							if dx < 0 and screen_manager then
								screen_manager.next()
								app.draw_current_screen()
							elseif dx > 0 and screen_manager then
								screen_manager.prev()
								app.draw_current_screen()
							end
						end
					end
				end
			end
		end

		-- Check for refresh
		local now = os.time()
		if now - last_refresh_check >= app.refresh_interval then
			last_refresh_check = now
			if wifi and wifi.is_connected() then
				print("Refreshing...")
				app.fetch_data()
				app.draw_current_screen()
			end
		end
	end
end

function app.stop()
	app.running = false
	print("App stopped")
end

app.start = app.run

return app
