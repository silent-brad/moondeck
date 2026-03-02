/*
 * Lua RTOS for CrowPanel ESP32-S3 5-inch Display
 * Main entry point - Moondeck
 */

#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_log.h"
#include "esp_heap_caps.h"
#include "nvs_flash.h"

#include "rgb_display.h"
#include "lua_core.h"
#include "lua_modules.h"

static const char *TAG = "LuaRTOS";

/* Core */
extern const uint8_t moondeck_lua_start[] asm("_binary_moondeck_lua_start");
extern const uint8_t moondeck_lua_end[] asm("_binary_moondeck_lua_end");

extern const uint8_t app_lua_start[] asm("_binary_app_lua_start");
extern const uint8_t app_lua_end[] asm("_binary_app_lua_end");

/* UI - Core */
extern const uint8_t ui_init_lua_start[] asm("_binary_ui_init_lua_start");
extern const uint8_t ui_init_lua_end[] asm("_binary_ui_init_lua_end");

extern const uint8_t ui_base_lua_start[] asm("_binary_ui_base_lua_start");
extern const uint8_t ui_base_lua_end[] asm("_binary_ui_base_lua_end");

/* UI - Layout */
extern const uint8_t container_lua_start[] asm("_binary_container_lua_start");
extern const uint8_t container_lua_end[] asm("_binary_container_lua_end");

extern const uint8_t row_lua_start[] asm("_binary_row_lua_start");
extern const uint8_t row_lua_end[] asm("_binary_row_lua_end");

extern const uint8_t column_lua_start[] asm("_binary_column_lua_start");
extern const uint8_t column_lua_end[] asm("_binary_column_lua_end");

extern const uint8_t ui_grid_lua_start[] asm("_binary_ui_grid_lua_start");
extern const uint8_t ui_grid_lua_end[] asm("_binary_ui_grid_lua_end");

extern const uint8_t spacer_lua_start[] asm("_binary_spacer_lua_start");
extern const uint8_t spacer_lua_end[] asm("_binary_spacer_lua_end");

/* UI - Display */
extern const uint8_t text_lua_start[] asm("_binary_text_lua_start");
extern const uint8_t text_lua_end[] asm("_binary_text_lua_end");

extern const uint8_t heading_lua_start[] asm("_binary_heading_lua_start");
extern const uint8_t heading_lua_end[] asm("_binary_heading_lua_end");

extern const uint8_t badge_lua_start[] asm("_binary_badge_lua_start");
extern const uint8_t badge_lua_end[] asm("_binary_badge_lua_end");

extern const uint8_t divider_lua_start[] asm("_binary_divider_lua_start");
extern const uint8_t divider_lua_end[] asm("_binary_divider_lua_end");

extern const uint8_t icon_lua_start[] asm("_binary_icon_lua_start");
extern const uint8_t icon_lua_end[] asm("_binary_icon_lua_end");

/* UI - Data */
extern const uint8_t value_lua_start[] asm("_binary_value_lua_start");
extern const uint8_t value_lua_end[] asm("_binary_value_lua_end");

extern const uint8_t progress_lua_start[] asm("_binary_progress_lua_start");
extern const uint8_t progress_lua_end[] asm("_binary_progress_lua_end");

extern const uint8_t chart_lua_start[] asm("_binary_chart_lua_start");
extern const uint8_t chart_lua_end[] asm("_binary_chart_lua_end");

extern const uint8_t table_lua_start[] asm("_binary_table_lua_start");
extern const uint8_t table_lua_end[] asm("_binary_table_lua_end");

extern const uint8_t list_lua_start[] asm("_binary_list_lua_start");
extern const uint8_t list_lua_end[] asm("_binary_list_lua_end");

/* UI - Feedback */
extern const uint8_t loading_lua_start[] asm("_binary_loading_lua_start");
extern const uint8_t loading_lua_end[] asm("_binary_loading_lua_end");

extern const uint8_t error_lua_start[] asm("_binary_error_lua_start");
extern const uint8_t error_lua_end[] asm("_binary_error_lua_end");

/* UI - Composite */
extern const uint8_t panel_lua_start[] asm("_binary_panel_lua_start");
extern const uint8_t panel_lua_end[] asm("_binary_panel_lua_end");

extern const uint8_t card_lua_start[] asm("_binary_card_lua_start");
extern const uint8_t card_lua_end[] asm("_binary_card_lua_end");

extern const uint8_t stat_lua_start[] asm("_binary_stat_lua_start");
extern const uint8_t stat_lua_end[] asm("_binary_stat_lua_end");

extern const uint8_t header_lua_start[] asm("_binary_header_lua_start");
extern const uint8_t header_lua_end[] asm("_binary_header_lua_end");

extern const uint8_t screen_indicator_lua_start[] asm("_binary_screen_indicator_lua_start");
extern const uint8_t screen_indicator_lua_end[] asm("_binary_screen_indicator_lua_end");

/* Plugins - Core */
extern const uint8_t plugins_init_lua_start[] asm("_binary_plugins_init_lua_start");
extern const uint8_t plugins_init_lua_end[] asm("_binary_plugins_init_lua_end");

extern const uint8_t plugin_base_lua_start[] asm("_binary_plugin_base_lua_start");
extern const uint8_t plugin_base_lua_end[] asm("_binary_plugin_base_lua_end");

extern const uint8_t registry_lua_start[] asm("_binary_registry_lua_start");
extern const uint8_t registry_lua_end[] asm("_binary_registry_lua_end");

/* Plugins - Weather */
extern const uint8_t weather_lua_start[] asm("_binary_weather_lua_start");
extern const uint8_t weather_lua_end[] asm("_binary_weather_lua_end");

extern const uint8_t weather_api_lua_start[] asm("_binary_weather_api_lua_start");
extern const uint8_t weather_api_lua_end[] asm("_binary_weather_api_lua_end");

extern const uint8_t icons_lua_start[] asm("_binary_icons_lua_start");
extern const uint8_t icons_lua_end[] asm("_binary_icons_lua_end");

/* Plugins - BTC */
extern const uint8_t btc_lua_start[] asm("_binary_btc_lua_start");
extern const uint8_t btc_lua_end[] asm("_binary_btc_lua_end");

extern const uint8_t btc_api_lua_start[] asm("_binary_btc_api_lua_start");
extern const uint8_t btc_api_lua_end[] asm("_binary_btc_api_lua_end");

/* Plugins - Other */
extern const uint8_t verse_lua_start[] asm("_binary_verse_lua_start");
extern const uint8_t verse_lua_end[] asm("_binary_verse_lua_end");

extern const uint8_t calendar_lua_start[] asm("_binary_calendar_lua_start");
extern const uint8_t calendar_lua_end[] asm("_binary_calendar_lua_end");

extern const uint8_t clock_lua_start[] asm("_binary_clock_lua_start");
extern const uint8_t clock_lua_end[] asm("_binary_clock_lua_end");

extern const uint8_t system_lua_start[] asm("_binary_system_lua_start");
extern const uint8_t system_lua_end[] asm("_binary_system_lua_end");

extern const uint8_t todo_lua_start[] asm("_binary_todo_lua_start");
extern const uint8_t todo_lua_end[] asm("_binary_todo_lua_end");

/* Screen Manager */
extern const uint8_t screen_manager_lua_start[] asm("_binary_screen_manager_lua_start");
extern const uint8_t screen_manager_lua_end[] asm("_binary_screen_manager_lua_end");

/* Touch */
extern const uint8_t swipe_lua_start[] asm("_binary_swipe_lua_start");
extern const uint8_t swipe_lua_end[] asm("_binary_swipe_lua_end");

extern const uint8_t handler_lua_start[] asm("_binary_handler_lua_start");
extern const uint8_t handler_lua_end[] asm("_binary_handler_lua_end");

/* Store */
extern const uint8_t store_lua_start[] asm("_binary_store_lua_start");
extern const uint8_t store_lua_end[] asm("_binary_store_lua_end");

/* Database */
extern const uint8_t db_lua_start[] asm("_binary_db_lua_start");
extern const uint8_t db_lua_end[] asm("_binary_db_lua_end");

/* Config */
extern const uint8_t config_lua_start[] asm("_binary_config_lua_start");
extern const uint8_t config_lua_end[] asm("_binary_config_lua_end");

extern const uint8_t screens_lua_start[] asm("_binary_screens_lua_start");
extern const uint8_t screens_lua_end[] asm("_binary_screens_lua_end");

/* Themes */
extern const uint8_t cyberpunk_lua_start[] asm("_binary_cyberpunk_lua_start");
extern const uint8_t cyberpunk_lua_end[] asm("_binary_cyberpunk_lua_end");

extern const uint8_t minimal_lua_start[] asm("_binary_minimal_lua_start");
extern const uint8_t minimal_lua_end[] asm("_binary_minimal_lua_end");

extern const uint8_t retro_lua_start[] asm("_binary_retro_lua_start");
extern const uint8_t retro_lua_end[] asm("_binary_retro_lua_end");

/* Layouts */
extern const uint8_t default_lua_start[] asm("_binary_default_lua_start");
extern const uint8_t default_lua_end[] asm("_binary_default_lua_end");

extern const uint8_t focus_lua_start[] asm("_binary_focus_lua_start");
extern const uint8_t focus_lua_end[] asm("_binary_focus_lua_end");

extern const uint8_t layout_grid_lua_start[] asm("_binary_layout_grid_lua_start");
extern const uint8_t layout_grid_lua_end[] asm("_binary_layout_grid_lua_end");

/* Env */
extern const uint8_t env_start[] asm("_binary__env_start");
extern const uint8_t env_end[] asm("_binary__env_end");

extern const uint8_t getenv_lua_start[] asm("_binary_getenv_lua_start");
extern const uint8_t getenv_lua_end[] asm("_binary_getenv_lua_end");

/* Plugin Configs */
extern const uint8_t weather_config_lua_start[] asm("_binary_weather_config_lua_start");
extern const uint8_t weather_config_lua_end[] asm("_binary_weather_config_lua_end");

extern const uint8_t btc_config_lua_start[] asm("_binary_btc_config_lua_start");
extern const uint8_t btc_config_lua_end[] asm("_binary_btc_config_lua_end");

extern const uint8_t verse_config_lua_start[] asm("_binary_verse_config_lua_start");
extern const uint8_t verse_config_lua_end[] asm("_binary_verse_config_lua_end");

extern const uint8_t todo_config_lua_start[] asm("_binary_todo_config_lua_start");
extern const uint8_t todo_config_lua_end[] asm("_binary_todo_config_lua_end");

extern const uint8_t calendar_config_lua_start[] asm("_binary_calendar_config_lua_start");
extern const uint8_t calendar_config_lua_end[] asm("_binary_calendar_config_lua_end");

extern const uint8_t clock_config_lua_start[] asm("_binary_clock_config_lua_start");
extern const uint8_t clock_config_lua_end[] asm("_binary_clock_config_lua_end");

extern const uint8_t system_config_lua_start[] asm("_binary_system_config_lua_start");
extern const uint8_t system_config_lua_end[] asm("_binary_system_config_lua_end");

static void register_embedded_module(lua_State *L, const char *name,
                                      const uint8_t *start, const uint8_t *end)
{
    size_t len = end - start;
    char *code = malloc(len + 1);
    if (code) {
        memcpy(code, start, len);
        code[len] = '\0';
        
        lua_getglobal(L, "package");
        lua_getfield(L, -1, "preload");
        
        if (luaL_loadstring(L, code) == LUA_OK) {
            lua_setfield(L, -2, name);
            ESP_LOGI(TAG, "Registered module: %s", name);
        } else {
            ESP_LOGE(TAG, "Failed to load module %s: %s", name, lua_tostring(L, -1));
            lua_pop(L, 1);
        }
        
        lua_pop(L, 2);
        free(code);
    }
}

static void register_embedded_string(lua_State *L, const char *name,
                                      const uint8_t *start, const uint8_t *end)
{
    size_t len = end - start;
    char *content = malloc(len + 1);
    if (content) {
        memcpy(content, start, len);
        content[len] = '\0';
        
        lua_getglobal(L, "package");
        lua_getfield(L, -1, "preload");
        
        lua_pushfstring(L, "return [[%s]]", content);
        if (luaL_loadstring(L, lua_tostring(L, -1)) == LUA_OK) {
            lua_remove(L, -2);
            lua_setfield(L, -2, name);
            ESP_LOGI(TAG, "Registered string: %s", name);
        } else {
            ESP_LOGE(TAG, "Failed to register string %s: %s", name, lua_tostring(L, -1));
            lua_pop(L, 2);
        }
        
        lua_pop(L, 2);
        free(content);
    }
}

static void register_all_modules(lua_State *L)
{
    ESP_LOGI(TAG, "Registering Lua modules...");
    
    /* Config and environment */
    register_embedded_string(L, "config.env", env_start, env_end);
    register_embedded_module(L, "getenv", getenv_lua_start, getenv_lua_end);
    register_embedded_module(L, "config", config_lua_start, config_lua_end);
    register_embedded_module(L, "config.screens", screens_lua_start, screens_lua_end);
    
    /* Themes */
    register_embedded_module(L, "config.themes.cyberpunk", cyberpunk_lua_start, cyberpunk_lua_end);
    register_embedded_module(L, "config.themes.minimal", minimal_lua_start, minimal_lua_end);
    register_embedded_module(L, "config.themes.retro", retro_lua_start, retro_lua_end);
    
    /* Layouts */
    register_embedded_module(L, "config.layouts.default", default_lua_start, default_lua_end);
    register_embedded_module(L, "config.layouts.focus", focus_lua_start, focus_lua_end);
    register_embedded_module(L, "config.layouts.grid", layout_grid_lua_start, layout_grid_lua_end);
    
    /* UI */
    register_embedded_module(L, "ui", ui_init_lua_start, ui_init_lua_end);
    register_embedded_module(L, "ui.base", ui_base_lua_start, ui_base_lua_end);
    
    /* UI - Layout */
    register_embedded_module(L, "ui.layout.container", container_lua_start, container_lua_end);
    register_embedded_module(L, "ui.layout.row", row_lua_start, row_lua_end);
    register_embedded_module(L, "ui.layout.column", column_lua_start, column_lua_end);
    register_embedded_module(L, "ui.layout.grid", ui_grid_lua_start, ui_grid_lua_end);
    register_embedded_module(L, "ui.layout.spacer", spacer_lua_start, spacer_lua_end);
    
    /* UI - Display */
    register_embedded_module(L, "ui.display.text", text_lua_start, text_lua_end);
    register_embedded_module(L, "ui.display.heading", heading_lua_start, heading_lua_end);
    register_embedded_module(L, "ui.display.badge", badge_lua_start, badge_lua_end);
    register_embedded_module(L, "ui.display.divider", divider_lua_start, divider_lua_end);
    register_embedded_module(L, "ui.display.icon", icon_lua_start, icon_lua_end);
    
    /* UI - Data */
    register_embedded_module(L, "ui.data.value", value_lua_start, value_lua_end);
    register_embedded_module(L, "ui.data.progress", progress_lua_start, progress_lua_end);
    register_embedded_module(L, "ui.data.chart", chart_lua_start, chart_lua_end);
    register_embedded_module(L, "ui.data.table", table_lua_start, table_lua_end);
    register_embedded_module(L, "ui.data.list", list_lua_start, list_lua_end);
    
    /* UI - Feedback */
    register_embedded_module(L, "ui.feedback.loading", loading_lua_start, loading_lua_end);
    register_embedded_module(L, "ui.feedback.error", error_lua_start, error_lua_end);
    
    /* UI - Composite */
    register_embedded_module(L, "ui.composite.panel", panel_lua_start, panel_lua_end);
    register_embedded_module(L, "ui.composite.card", card_lua_start, card_lua_end);
    register_embedded_module(L, "ui.composite.stat", stat_lua_start, stat_lua_end);
    register_embedded_module(L, "ui.composite.header", header_lua_start, header_lua_end);
    register_embedded_module(L, "ui.composite.screen_indicator", screen_indicator_lua_start, screen_indicator_lua_end);
    
    /* Plugins */
    register_embedded_module(L, "plugins", plugins_init_lua_start, plugins_init_lua_end);
    register_embedded_module(L, "plugins.base", plugin_base_lua_start, plugin_base_lua_end);
    register_embedded_module(L, "plugins.registry", registry_lua_start, registry_lua_end);
    
    /* Plugins - Builtin */
    register_embedded_module(L, "plugins.builtin.weather", weather_lua_start, weather_lua_end);
    register_embedded_module(L, "plugins.builtin.weather.api", weather_api_lua_start, weather_api_lua_end);
    register_embedded_module(L, "plugins.builtin.weather.icons", icons_lua_start, icons_lua_end);
    register_embedded_module(L, "plugins.builtin.btc", btc_lua_start, btc_lua_end);
    register_embedded_module(L, "plugins.builtin.btc.api", btc_api_lua_start, btc_api_lua_end);
    register_embedded_module(L, "plugins.builtin.verse", verse_lua_start, verse_lua_end);
    register_embedded_module(L, "plugins.builtin.calendar", calendar_lua_start, calendar_lua_end);
    register_embedded_module(L, "plugins.builtin.clock", clock_lua_start, clock_lua_end);
    register_embedded_module(L, "plugins.builtin.system", system_lua_start, system_lua_end);
    register_embedded_module(L, "plugins.builtin.todo", todo_lua_start, todo_lua_end);
    
    /* Screen Manager */
    register_embedded_module(L, "screen_manager", screen_manager_lua_start, screen_manager_lua_end);
    
    /* Touch */
    register_embedded_module(L, "touch.swipe", swipe_lua_start, swipe_lua_end);
    register_embedded_module(L, "touch.handler", handler_lua_start, handler_lua_end);
    
    /* Store & DB */
    register_embedded_module(L, "store", store_lua_start, store_lua_end);
    register_embedded_module(L, "db", db_lua_start, db_lua_end);
    
    /* Plugin Configs */
    register_embedded_module(L, "config.plugins.weather", weather_config_lua_start, weather_config_lua_end);
    register_embedded_module(L, "config.plugins.btc", btc_config_lua_start, btc_config_lua_end);
    register_embedded_module(L, "config.plugins.verse", verse_config_lua_start, verse_config_lua_end);
    register_embedded_module(L, "config.plugins.todo", todo_config_lua_start, todo_config_lua_end);
    register_embedded_module(L, "config.plugins.calendar", calendar_config_lua_start, calendar_config_lua_end);
    register_embedded_module(L, "config.plugins.clock", clock_config_lua_start, clock_config_lua_end);
    register_embedded_module(L, "config.plugins.system", system_config_lua_start, system_config_lua_end);
    
    /* App entry point */
    register_embedded_module(L, "moondeck", moondeck_lua_start, moondeck_lua_end);
    register_embedded_module(L, "app", app_lua_start, app_lua_end);
    
    ESP_LOGI(TAG, "All modules registered");
}

// Forward declare WiFi pre-init
void wifi_preinit(void);

void app_main(void)
{
    ESP_LOGI(TAG, "Moondeck v1");
    
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    ESP_LOGI(TAG, "Free heap: %u bytes", (unsigned int)esp_get_free_heap_size());
    ESP_LOGI(TAG, "Free internal: %u bytes", (unsigned int)heap_caps_get_free_size(MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT));
    ESP_LOGI(TAG, "Free PSRAM: %u bytes", (unsigned int)heap_caps_get_free_size(MALLOC_CAP_SPIRAM));

    // Initialize WiFi BEFORE display to reserve internal DMA memory for WiFi buffers
    ESP_LOGI(TAG, "Pre-initializing WiFi (before display)...");
    wifi_preinit();
    ESP_LOGI(TAG, "Free internal after WiFi: %u bytes", (unsigned int)heap_caps_get_free_size(MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT));

    ESP_LOGI(TAG, "Initializing RGB display...");
    ret = rgb_display_init();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to initialize RGB display: %s", esp_err_to_name(ret));
    } else {
        ESP_LOGI(TAG, "RGB display initialized successfully");
        rgb_display_clear(RGB565_BLACK);
    }

    ESP_LOGI(TAG, "Initializing Lua...");
    lua_core_init();
    
    lua_State *L = lua_core_get_state();
    if (L) {
        lua_modules_init(L);
        register_all_modules(L);
        
        ESP_LOGI(TAG, "Running Moondeck...");
        lua_core_dostring("require('app').run()");
    }
    
    lua_core_run_repl();
}
