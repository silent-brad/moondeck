idf_component_register(
    SRCS "main.c"
    INCLUDE_DIRS "."
    REQUIRES rgb_display lua_core lua_modules
    PRIV_REQUIRES nvs_flash esp_psram
    EMBED_TXTFILES 
        # Core
        "../lua/moondeck.lua"
        "../lua/app.lua"

        # UI - Core
        "../lua/ui/ui_init.lua"
        "../lua/ui/ui_base.lua"

        # UI - Layout
        "../lua/ui/layout/container.lua"
        "../lua/ui/layout/row.lua"
        "../lua/ui/layout/column.lua"
        "../lua/ui/layout/ui_grid.lua"
        "../lua/ui/layout/spacer.lua"

        # UI - Display
        "../lua/ui/display/text.lua"
        "../lua/ui/display/heading.lua"
        "../lua/ui/display/badge.lua"
        "../lua/ui/display/divider.lua"
        "../lua/ui/display/icon.lua"

        # UI - Data
        "../lua/ui/data/value.lua"
        "../lua/ui/data/progress.lua"
        "../lua/ui/data/chart.lua"
        "../lua/ui/data/table.lua"
        "../lua/ui/data/list.lua"

        # UI - Feedback
        "../lua/ui/feedback/loading.lua"
        "../lua/ui/feedback/error.lua"

        # UI - Composite
        "../lua/ui/composite/panel.lua"
        "../lua/ui/composite/card.lua"
        "../lua/ui/composite/stat.lua"
        "../lua/ui/composite/header.lua"
        "../lua/ui/composite/screen_indicator.lua"

        # Plugins - Core
        "../lua/plugins/plugins_init.lua"
        "../lua/plugins/plugin_base.lua"
        "../lua/plugins/registry.lua"

        # Plugins - Weather
        "../lua/plugins/builtin/weather/weather.lua"
        "../lua/plugins/builtin/weather/weather_api.lua"
        "../lua/plugins/builtin/weather/icons.lua"

        # Plugins - BTC
        "../lua/plugins/builtin/btc/btc.lua"
        "../lua/plugins/builtin/btc/btc_api.lua"

        # Plugins - Other
        "../lua/plugins/builtin/verse/verse.lua"
        "../lua/plugins/builtin/calendar/calendar.lua"
        "../lua/plugins/builtin/clock/clock.lua"
        "../lua/plugins/builtin/system/system.lua"
        "../lua/plugins/builtin/todo/todo.lua"

        # Screen Manager
        "../lua/screen_manager/screen_manager.lua"

        # Touch
        "../lua/touch/swipe.lua"
        "../lua/touch/handler.lua"

        # Store
        "../lua/store/store.lua"

        # Database
        "../lua/db/db.lua"

        # Config
        "../config/config.lua"
        "../config/screens.lua"
        "../config/themes/cyberpunk.lua"
        "../config/themes/minimal.lua"
        "../config/themes/retro.lua"
        "../config/layouts/default.lua"
        "../config/layouts/focus.lua"
        "../config/layouts/layout_grid.lua"
        "../config/.env"

        # Plugin Configs
        "../config/plugins/weather_config.lua"
        "../config/plugins/btc_config.lua"
        "../config/plugins/verse_config.lua"
        "../config/plugins/todo_config.lua"
        "../config/plugins/calendar_config.lua"
        "../config/plugins/clock_config.lua"
        "../config/plugins/system_config.lua"

        # Existing
        "getenv.lua"
)
