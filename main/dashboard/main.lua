--[[
Moondeck
Main entry point - coordinates all components
--]]

dashboard = {}

local ui = nil
local weather_mod = nil
local btc_mod = nil
local verse_mod = nil
local cfg = nil

dashboard.running = false
dashboard.last_refresh = 0
dashboard.refresh_interval = 300

function dashboard.load_modules()
	local status = { ui = false, weather = false, btc = false, verse = false, config = false }

	local ok, mod = pcall(require, "config")
	if ok and mod then
		cfg = mod
		status.config = true
		dashboard.refresh_interval = cfg.display.refresh_interval or 300
	else
		print("Failed to load config: " .. tostring(mod))
	end

	ok, mod = pcall(require, "dashboard.init")
	if ok and mod then
		ui = mod
		status.ui = true
	else
		print("Failed to load dashboard.init: " .. tostring(mod))
	end

	ok, mod = pcall(require, "dashboard.weather")
	if ok and mod then
		weather_mod = mod
		status.weather = true
	else
		print("Failed to load dashboard.weather: " .. tostring(mod))
	end

	ok, mod = pcall(require, "dashboard.btc")
	if ok and mod then
		btc_mod = mod
		status.btc = true
	else
		print("Failed to load dashboard.btc: " .. tostring(mod))
	end

	ok, mod = pcall(require, "dashboard.verse")
	if ok and mod then
		verse_mod = mod
		status.verse = true
	else
		print("Failed to load dashboard.verse: " .. tostring(mod))
	end

	return status
end

function dashboard.connect_wifi()
	if not wifi then
		print("WiFi module not available")
		return false
	end

	if not cfg then
		print("Config not loaded")
		return false
	end

	print("Connecting to WiFi: " .. cfg.wifi.ssid)

	local ok = wifi.connect(cfg.wifi.ssid, cfg.wifi.password)

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

function dashboard.fetch_all_data()
	print("Fetching data...")

	if weather_mod and http and cfg then
		local w = cfg.weather
		weather_mod.fetch(w.api_key, w.city, w.country, w.units)
	end

	if btc_mod and http then
		btc_mod.fetch()
	end

	if verse_mod and http then
		verse_mod.fetch()
	end

	dashboard.last_refresh = os.time()
	print("Data fetch complete")
end

function dashboard.draw()
	if not ui then
		return
	end

	ui.clear()
	ui.draw_header("MOONDECK DASHBOARD")

	ui.draw_panel(ui.panels.weather, "WEATHER", function(x, y, w, h)
		if weather_mod then
			weather_mod.draw(x, y, w, h, ui.theme)
		else
			display.text_font(x, y + 20, "Module not loaded", ui.theme.text_secondary, display.FONT_INTER_20)
		end
	end)

	ui.draw_panel(ui.panels.btc, "BITCOIN", function(x, y, w, h)
		if btc_mod then
			btc_mod.draw(x, y, w, h, ui.theme)
		else
			display.text_font(x, y + 20, "Module not loaded", ui.theme.text_secondary, display.FONT_INTER_20)
		end
	end)

	ui.draw_panel(ui.panels.verse, "DAILY VERSE", function(x, y, w, h)
		if verse_mod then
			verse_mod.draw(x, y, w, h, ui.theme)
		else
			display.text_font(x, y + 20, "Module not loaded", ui.theme.text_secondary, display.FONT_INTER_20)
		end
	end)

	dashboard.draw_status_bar()
end

function dashboard.draw_status_bar()
	if not ui then
		return
	end

	local y = math.floor(ui.cfg.height - 18)
	local t = ui.theme
	local w = math.floor(ui.cfg.width)

	display.rect(0, y - 2, w, 20, t.bg_secondary, true)
	display.line(0, y - 2, w, y - 2, t.border)

	local wifi_status = "WiFi: --"
	if wifi then
		if wifi.is_connected() then
			wifi_status = "WiFi: OK"
			display.text_font(5, y, wifi_status, display.rgb(0, 255, 100), display.FONT_INTER_20)
		else
			wifi_status = "WiFi: X"
			display.text_font(5, y, wifi_status, display.rgb(255, 80, 80), display.FONT_INTER_20)
		end
	else
		display.text_font(5, y, wifi_status, t.text_secondary, display.FONT_INTER_20)
	end

	local next_refresh = dashboard.refresh_interval - (os.time() - dashboard.last_refresh)
	if next_refresh < 0 then
		next_refresh = 0
	end
	local refresh_str = string.format("Next update: %ds", math.floor(next_refresh))
	display.text_font(w - 180, y, refresh_str, t.text_secondary, display.FONT_INTER_20)

	local mem = collectgarbage("count")
	local mem_str = string.format("Mem: %.1fKB", mem)
	display.text_font(math.floor(w / 2 - 50), y, mem_str, t.border, display.FONT_INTER_20)
end

function dashboard.init()
	print("Initializing Moondeck Dashboard...")

	local status = dashboard.load_modules()
	print(
		"Modules loaded:",
		"ui=" .. tostring(status.ui),
		"weather=" .. tostring(status.weather),
		"btc=" .. tostring(status.btc),
		"verse=" .. tostring(status.verse)
	)

	if ui then
		ui.init()
	else
		display.init()
	end

	return true
end

function dashboard.run()
	if not dashboard.init() then
		print("Dashboard initialization failed")
		return
	end

	dashboard.running = true

	-- Show splash screen immediately so user sees something
	dashboard.draw_splash()

	local wifi_ok = dashboard.connect_wifi()

	if wifi_ok then
		dashboard.fetch_all_data()
	end

	dashboard.draw()
	print("Dashboard drawn. Sleeping until next refresh...")

	while dashboard.running do
		sys.sleep(dashboard.refresh_interval * 1000)

		if wifi and wifi.is_connected() then
			print("Refreshing data...")
			dashboard.fetch_all_data()
			dashboard.draw()
			print("Refresh complete.")
		end
	end
end

function dashboard.draw_splash()
	if not ui then
		display.clear(display.BLACK)
		display.text_font(300, 200, "MOONDECK", display.CYAN, display.FONT_GARAMOND_20)
		display.text_font(280, 230, "Cyberpunk Dashboard", display.WHITE, display.FONT_GARAMOND_20)
		display.text_font(280, 260, "Connecting...", display.YELLOW, display.FONT_INTER_20)
		return
	end

	ui.clear()

	local t = ui.theme
	local cx = math.floor(ui.cfg.width / 2)
	local cy = math.floor(ui.cfg.height / 2)

	for i = 1, 5 do
		display.rect(cx - 200 - i * 10, cy - 80 - i * 5, 400 + i * 20, 160 + i * 10, t.glow, false)
	end

	display.rect(cx - 200, cy - 80, 400, 160, t.bg_secondary, true)
	display.rect(cx - 200, cy - 80, 400, 160, t.accent_cyan, false)

	display.line(cx - 200, cy - 80, cx - 180, cy - 60, t.accent_cyan)
	display.line(cx + 200, cy - 80, cx + 180, cy - 60, t.accent_cyan)
	display.line(cx - 200, cy + 80, cx - 180, cy + 60, t.accent_cyan)
	display.line(cx + 200, cy + 80, cx + 180, cy + 60, t.accent_cyan)

	display.text_font(cx - 60, cy - 30, "MOONDECK", t.accent_cyan, display.FONT_GARAMOND_20)
	display.text_font(cx - 90, cy, "CYBERPUNK DASHBOARD", t.accent_magenta, display.FONT_GARAMOND_20)
	display.text_font(cx - 55, cy + 30, "v1.0.0", t.text_secondary, display.FONT_INTER_20)

	display.text_font(cx - 70, cy + 60, "Connecting...", t.accent_yellow, display.FONT_INTER_20)
end

function dashboard.stop()
	dashboard.running = false
	print("Dashboard stopped")
end

function dashboard.get_config()
	return cfg
end

dashboard.start = dashboard.run

return dashboard
