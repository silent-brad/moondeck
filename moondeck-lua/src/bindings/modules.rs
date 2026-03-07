use anyhow::Result;
use moondeck_core::gfx::Color;
use piccolo::{Callback, CallbackReturn, Lua, String as LuaString, Table, Value};
use std::sync::RwLock;

use crate::bindings::gfx::{get_draw_commands, get_draw_offset};

// Auto-generated theme definitions from config/theme.lua
include!(concat!(env!("OUT_DIR"), "/embedded_themes.rs"));

// Global current theme state (accessible from Rust)
static CURRENT_THEME: RwLock<String> = RwLock::new(String::new());

/// Get the current theme name
pub fn get_current_theme() -> String {
    CURRENT_THEME.read().unwrap().clone()
}

/// Get the current theme's background color
pub fn get_theme_bg_primary() -> &'static str {
    let theme_name = CURRENT_THEME.read().unwrap();
    let theme = get_theme(&theme_name);
    theme.bg_primary
}

/// Get available theme names
#[allow(dead_code)]
pub fn get_theme_names() -> &'static [&'static str] {
    THEME_NAMES
}

fn create_theme_colors_table<'gc>(ctx: piccolo::Context<'gc>, theme_name: &str) -> Table<'gc> {
    let colors = Table::new(&ctx);
    let theme = get_theme(theme_name);

    let _ = colors.set(ctx, "name", ctx.intern(theme_name.as_bytes()));
    // Background colors
    let _ = colors.set(ctx, "bg_primary", ctx.intern(theme.bg_primary.as_bytes()));
    let _ = colors.set(ctx, "bg_secondary", ctx.intern(theme.bg_secondary.as_bytes()));
    let _ = colors.set(ctx, "bg_tertiary", ctx.intern(theme.bg_tertiary.as_bytes()));
    let _ = colors.set(ctx, "bg_card", ctx.intern(theme.bg_card.as_bytes()));
    // Text colors
    let _ = colors.set(ctx, "text_primary", ctx.intern(theme.text_primary.as_bytes()));
    let _ = colors.set(ctx, "text_secondary", ctx.intern(theme.text_secondary.as_bytes()));
    let _ = colors.set(ctx, "text_muted", ctx.intern(theme.text_muted.as_bytes()));
    let _ = colors.set(ctx, "text_accent", ctx.intern(theme.text_accent.as_bytes()));
    // Accent colors
    let _ = colors.set(ctx, "accent_primary", ctx.intern(theme.accent_primary.as_bytes()));
    let _ = colors.set(ctx, "accent_secondary", ctx.intern(theme.accent_secondary.as_bytes()));
    let _ = colors.set(ctx, "accent_success", ctx.intern(theme.accent_success.as_bytes()));
    let _ = colors.set(ctx, "accent_warning", ctx.intern(theme.accent_warning.as_bytes()));
    let _ = colors.set(ctx, "accent_error", ctx.intern(theme.accent_error.as_bytes()));
    // Border colors
    let _ = colors.set(ctx, "border_primary", ctx.intern(theme.border_primary.as_bytes()));
    let _ = colors.set(ctx, "border_accent", ctx.intern(theme.border_accent.as_bytes()));
    // Component specific
    let _ = colors.set(ctx, "card_radius", theme.card_radius);
    let _ = colors.set(ctx, "border_width", theme.border_width);

    colors
}

pub fn register_modules(lua: &mut Lua) -> Result<()> {
    // Initialize global theme state with default from config/theme.lua
    {
        let mut theme = CURRENT_THEME.write().unwrap();
        if theme.is_empty() {
            *theme = DEFAULT_THEME.to_string();
        }
    }

    lua.try_enter(|ctx| {
        // Create theme module
        let theme_table = Table::new(&ctx);

        theme_table.set(
            ctx,
            "set",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let (_self_table, theme_name): (Value, LuaString) = stack.consume(ctx)?;
                let theme_str = theme_name.to_str().unwrap_or("dark").to_string();
                // Update global theme state
                *CURRENT_THEME.write().unwrap() = theme_str;
                stack.replace(ctx, true);
                Ok(CallbackReturn::Return)
            }),
        )?;

        theme_table.set(
            ctx,
            "get",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let theme = CURRENT_THEME.read().unwrap().clone();
                let colors = create_theme_colors_table(ctx, &theme);
                stack.replace(ctx, colors);
                Ok(CallbackReturn::Return)
            }),
        )?;

        ctx.set_global("__theme_module", theme_table)?;

        // Create layout module (stub)
        let layout_table = Table::new(&ctx);
        layout_table.set(
            ctx,
            "grid",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                stack.replace(ctx, Table::new(&ctx));
                Ok(CallbackReturn::Return)
            }),
        )?;
        ctx.set_global("__layout_module", layout_table)?;

        // Create components module
        let components_table = Table::new(&ctx);

        // components.new - stub
        components_table.set(
            ctx,
            "new",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                stack.replace(ctx, Table::new(&ctx));
                Ok(CallbackReturn::Return)
            }),
        )?;

        // components.card(gfx, x, y, w, h, opts)
        components_table.set(
            ctx,
            "card",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let (gfx, x, y, w, h, opts): (Value, i64, i64, i64, i64, Value) = stack.consume(ctx)?;

                let (offset_x, offset_y) = get_draw_offset();
                let abs_x = offset_x + x as u32;
                let abs_y = offset_y + y as u32;

                // Get current theme colors as defaults
                let theme_name = CURRENT_THEME.read().unwrap();
                let theme = get_theme(&theme_name);
                let mut bg_color = Color::from_hex(theme.bg_card).unwrap_or(Color::BLACK);
                let mut border_color = Color::from_hex(theme.border_primary).unwrap_or(Color::GRAY);

                if let Value::Table(opts_table) = opts {
                    if let Value::String(bg) = opts_table.get(ctx, "bg") {
                        if let Some(c) = Color::from_hex(bg.to_str().unwrap_or(theme.bg_card)) {
                            bg_color = c;
                        }
                    }
                    if let Value::String(border) = opts_table.get(ctx, "border") {
                        if let Some(c) = Color::from_hex(border.to_str().unwrap_or(theme.border_primary)) {
                            border_color = c;
                        }
                    }
                }

                let draw_cmds = get_draw_commands();
                draw_cmds.fill_rect(abs_x, abs_y, w as u32, h as u32, bg_color);
                draw_cmds.stroke_rect(abs_x, abs_y, w as u32, h as u32, border_color, 1);

                stack.replace(ctx, gfx);
                Ok(CallbackReturn::Return)
            }),
        )?;

        // components.title_bar(gfx, x, y, width, title, opts) -> returns height
        components_table.set(
            ctx,
            "title_bar",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let (_gfx, x, y, _width, title, opts): (Value, i64, i64, i64, LuaString, Value) = stack.consume(ctx)?;

                let (offset_x, offset_y) = get_draw_offset();
                let abs_x = (offset_x as i64 + x) as i32;
                let abs_y = (offset_y as i64 + y) as i32;

                // Get current theme colors as defaults
                let theme_name = CURRENT_THEME.read().unwrap();
                let theme = get_theme(&theme_name);
                let mut accent_color = Color::from_hex(theme.accent_primary).unwrap_or(Color::CYAN);
                let text_color = Color::from_hex(theme.text_primary).unwrap_or(Color::WHITE);

                if let Value::Table(opts_table) = opts {
                    if let Value::String(accent) = opts_table.get(ctx, "accent") {
                        if let Some(c) = Color::from_hex(accent.to_str().unwrap_or(theme.accent_primary)) {
                            accent_color = c;
                        }
                    }
                }

                let draw_cmds = get_draw_commands();
                let title_str = title.to_str().unwrap_or("Widget");
                draw_cmds.text(abs_x, abs_y, title_str, text_color, moondeck_core::gfx::Font::Large);
                draw_cmds.line(abs_x, abs_y + 22, abs_x + 60, abs_y + 22, accent_color, 2);

                stack.replace(ctx, 30i64);
                Ok(CallbackReturn::Return)
            }),
        )?;

        // components.loading(gfx, x, y)
        components_table.set(
            ctx,
            "loading",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let (_gfx, x, y): (Value, i64, i64) = stack.consume(ctx)?;

                let (offset_x, offset_y) = get_draw_offset();
                let abs_x = (offset_x as i64 + x) as i32;
                let abs_y = (offset_y as i64 + y) as i32;

                // Get current theme colors
                let theme_name = CURRENT_THEME.read().unwrap();
                let theme = get_theme(&theme_name);
                let text_color = Color::from_hex(theme.text_muted).unwrap_or(Color::GRAY);

                let draw_cmds = get_draw_commands();
                draw_cmds.text(abs_x, abs_y, "Loading...", text_color, moondeck_core::gfx::Font::Medium);

                stack.replace(ctx, Value::Nil);
                Ok(CallbackReturn::Return)
            }),
        )?;

        // components.error(gfx, x, y, width, message)
        components_table.set(
            ctx,
            "error",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let (_gfx, x, y, _width, message): (Value, i64, i64, i64, LuaString) = stack.consume(ctx)?;

                let (offset_x, offset_y) = get_draw_offset();
                let abs_x = (offset_x as i64 + x) as i32;
                let abs_y = (offset_y as i64 + y) as i32;

                // Get current theme colors
                let theme_name = CURRENT_THEME.read().unwrap();
                let theme = get_theme(&theme_name);
                let error_color = Color::from_hex(theme.accent_error).unwrap_or(Color::RED);

                let draw_cmds = get_draw_commands();
                let msg = message.to_str().unwrap_or("Error");
                draw_cmds.text(abs_x, abs_y, msg, error_color, moondeck_core::gfx::Font::Medium);

                stack.replace(ctx, Value::Nil);
                Ok(CallbackReturn::Return)
            }),
        )?;

        // components.item_row(gfx, x, y, width, label, value, opts)
        components_table.set(
            ctx,
            "item_row",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let (_gfx, x, y, _width, label, value, _opts): (Value, i64, i64, i64, LuaString, LuaString, Value) = stack.consume(ctx)?;

                let (offset_x, offset_y) = get_draw_offset();
                let abs_x = (offset_x as i64 + x) as i32;
                let abs_y = (offset_y as i64 + y) as i32;

                // Get current theme colors
                let theme_name = CURRENT_THEME.read().unwrap();
                let theme = get_theme(&theme_name);
                let label_color = Color::from_hex(theme.text_secondary).unwrap_or(Color::GRAY);
                let value_color = Color::from_hex(theme.text_primary).unwrap_or(Color::WHITE);

                let draw_cmds = get_draw_commands();
                let label_str = label.to_str().unwrap_or("");
                let value_str = value.to_str().unwrap_or("");

                draw_cmds.text(abs_x, abs_y, label_str, label_color, moondeck_core::gfx::Font::Small);
                draw_cmds.text(abs_x + 80, abs_y, value_str, value_color, moondeck_core::gfx::Font::Small);

                stack.replace(ctx, Value::Nil);
                Ok(CallbackReturn::Return)
            }),
        )?;

        ctx.set_global("__components_module", components_table)?;

        // Create require function
        ctx.set_global(
            "require",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let module_name: LuaString = stack.consume(ctx)?;
                let module_str = module_name.to_str().unwrap_or("");

                let result = match module_str {
                    "theme" => ctx.globals().get(ctx, "__theme_module"),
                    "layout" => ctx.globals().get(ctx, "__layout_module"),
                    "components" => ctx.globals().get(ctx, "__components_module"),
                    _ => Value::Nil,
                };

                if matches!(result, Value::Nil) {
                    let msg = format!("module '{}' not found", module_str);
                    let err_val: Value = ctx.intern(msg.as_bytes()).into();
                    return Err(piccolo::Error::from_value(err_val));
                }

                stack.replace(ctx, result);
                Ok(CallbackReturn::Return)
            }),
        )?;

        Ok(())
    })?;

    Ok(())
}
