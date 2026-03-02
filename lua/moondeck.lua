--[[
Moondeck - Main Lua Entry Point
Initializes all modules and starts the dashboard
--]]

local M = {}

function M.init()
	print("Initializing Moondeck modules...")

	-- Load core modules
	local ok, err

	ok, M.ui = pcall(require, "ui")
	if not ok then
		print("Failed to load ui: " .. tostring(M.ui))
	end

	ok, M.plugins = pcall(require, "plugins")
	if not ok then
		print("Failed to load plugins: " .. tostring(M.plugins))
	end

	ok, M.screen_manager = pcall(require, "screen_manager")
	if not ok then
		print("Failed to load screen_manager: " .. tostring(M.screen_manager))
	end

	ok, M.touch = pcall(require, "touch.handler")
	if not ok then
		print("Failed to load touch.handler: " .. tostring(M.touch))
	end

	ok, M.store = pcall(require, "store")
	if not ok then
		print("Failed to load store: " .. tostring(M.store))
	end

	print("Moondeck modules initialized")
	return true
end

return M
