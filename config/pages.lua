-- Moondeck Pages Configuration
-- This is the main configuration file for your Moondeck dashboard.
-- Define your display pages and widgets here.
--
-- Layout Templates Available:
--   full          - Single full-screen widget
--   half_half     - Two equal columns
--   thirds        - Three equal columns
--   main_sidebar  - Large left (8 cols) + two stacked right (4 cols)
--   header_two_col - Header row + two columns below
--   quad          - 2x2 grid
--   dashboard     - Main area + sidebar widgets

local sysinfo = require("widgets.sysinfo")
local weather = require("widgets.weather")
local quote = require("widgets.quote")
local crypto = require("widgets.crypto")
local clock = require("widgets.clock")
local status = require("widgets.status")
local bible = require("widgets.bible")
local rss = require("widgets.rss")
local stocks = require("widgets.stocks")
local github = require("widgets.github")
local chess = require("widgets.chess")
local slideshow = require("widgets.slideshow")

return {
  page_switch_interval = env.get("PAGE_SWITCH_INTERVAL") or 60000, -- auto-switch pages every 1 minute (nil to disable)
  pages = {
    {
      id = "dashboard",
      title = "Dashboard",
      layout = "quad",
      widgets = {
        {
          widget = sysinfo,
          update_interval = 1000,
          opts = {},
        },
        {
          widget = status,
          update_interval = 1000,
          opts = {},
        },
        {
          widget = weather,
          update_interval = 300000,
          opts = {},
        },
        {
          widget = clock,
          update_interval = 1000,
          opts = {
            timezone = env.get("TIMEZONE"),
            show_seconds = true,
            show_date = true,
            format_24h = false,
          },
        },
      },
    },

    {
      id = "home",
      title = "Home",
      layout = "half_half",
      widgets = {
        {
          widget = chess,
          update_interval = 300000,
          opts = {
            username = env.get("CHESS_USERNAME"),
          },
        },
        {
          widget = quote,
          update_interval = 60000,
          opts = {},
        },
      },
    },

    {
      id = "stocks",
      title = "Stocks",
      layout = "half_half",
      widgets = {
        {
          widget = crypto,
          update_interval = 60000,
          opts = {
            coins = { "bitcoin", "ethereum", "solana", "monero" },
          },
        },
        {
          widget = stocks,
          update_interval = 60000,
          opts = {
            symbols = { "AAPL", "GOOGL", "PLTR", "TSLA", "MO" },
          },
        },
      },
    },

    {
      id = "reading",
      title = "Reading",
      layout = "half_half",
      widgets = {
        {
          widget = bible,
          update_interval = 3600000,
          opts = {},
        },
        {
          widget = rss,
          update_interval = 300000,
          opts = {},
        },
      },
    },

    {
      id = "heatmap",
      title = "GitHub Heatmap",
      layout = "full",
      widgets = {
        {
          widget = github,
          update_interval = 3000,
          opts = {},
        },
      },
    },

    {
      id = "gallery",
      title = "Lord Leighton",
      layout = "full",
      widgets = {
        {
          widget = slideshow,
          update_interval = 1000,
          opts = {
            interval = 10,
            fetch_urls = {
              "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/Leighton_The_Painter-s_Honeymoon_1864.jpg/200px-Leighton_The_Painter-s_Honeymoon_1864.jpg",
              "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Flaming_June%2C_by_Frederic_Lord_Leighton_%281830-1896%29.jpg/200px-Flaming_June%2C_by_Frederic_Lord_Leighton_%281830-1896%29.jpg",
              "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Golden_hours%2C_by_Frederic_Leighton.jpg/200px-Golden_hours%2C_by_Frederic_Leighton.jpg",
              "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b4/Amarilla_Leighton.jpg/200px-Amarilla_Leighton.jpg",
              "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/Frederick_Leighton_-_The_golden_hours.jpg/200px-Frederick_Leighton_-_The_golden_hours.jpg",
            },
          },
        },
      },
    },
  },
}
