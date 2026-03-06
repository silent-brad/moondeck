use crate::bindings;
use anyhow::{Context, Result};
use moondeck_core::ui::{Page, WidgetInstance};
use moondeck_hal::EnvConfig;
use piccolo::{Closure, Executor, Lua, StashedExecutor, Table, Value};

const EMBEDDED_INIT_LUA: &str = include_str!("../../config/init.lua");
const EMBEDDED_PAGES_LUA: &str = include_str!("../../config/pages.lua");

pub struct LuaRuntime {
    lua: Lua,
    executor: Option<StashedExecutor>,
    config_path: Option<String>,
}

impl LuaRuntime {
    pub fn new() -> Result<Self> {
        let lua = Lua::full();
        Ok(Self {
            lua,
            executor: None,
            config_path: None,
        })
    }

    pub fn with_config_path(mut self, path: &str) -> Self {
        self.config_path = Some(path.to_string());
        self
    }

    pub fn init(&mut self, env: &EnvConfig) -> Result<()> {
        bindings::register_all(&mut self.lua, env)
            .context("Failed to register Lua bindings")?;

        self.load_script(EMBEDDED_INIT_LUA)?;
        self.run_pending().context("Failed to run init.lua")?;
        Ok(())
    }

    pub fn load_script(&mut self, script: &str) -> Result<()> {
        let executor = self.lua.try_enter(|ctx| {
            let closure = Closure::load(ctx, None, script.as_bytes())
                .map_err(|e| anyhow::anyhow!("Failed to load script: {:?}", e))?;
            let executor = Executor::start(ctx, closure.into(), ());
            Ok(ctx.stash(executor))
        })?;
        self.executor = Some(executor);
        Ok(())
    }

    pub fn run_pending(&mut self) -> Result<()> {
        if let Some(ref executor) = self.executor {
            self.lua.execute::<()>(executor)
                .map_err(|e| anyhow::anyhow!("Lua execution error: {:?}", e))?;
        }
        Ok(())
    }

    pub fn load_file(&mut self, path: &str) -> Result<()> {
        let content = std::fs::read_to_string(path)
            .with_context(|| format!("Failed to read Lua file: {}", path))?;
        self.load_script(&content)?;
        self.run_pending()
            .with_context(|| format!("Failed to execute Lua file: {}", path))
    }

    pub fn load_pages(&mut self) -> Result<Vec<Page>> {
        self.load_pages_from_config()
            .or_else(|e| {
                log::warn!("Failed to load pages from config: {}, using demo pages", e);
                Ok(create_demo_pages())
            })
    }

    fn load_pages_from_config(&mut self) -> Result<Vec<Page>> {
        let pages_lua = if let Some(ref config_path) = self.config_path {
            let pages_path = format!("{}/pages.lua", config_path);
            std::fs::read_to_string(&pages_path).unwrap_or_else(|_| EMBEDDED_PAGES_LUA.to_string())
        } else {
            EMBEDDED_PAGES_LUA.to_string()
        };

        parse_pages_config(&pages_lua)
    }

    pub fn lua(&mut self) -> &mut Lua {
        &mut self.lua
    }
}

#[derive(Debug, Clone, serde::Deserialize)]
struct PagesConfig {
    pages: Vec<PageConfig>,
}

#[derive(Debug, Clone, serde::Deserialize)]
struct PageConfig {
    id: String,
    title: Option<String>,
    background: Option<String>,
    #[serde(default)]
    widgets: Vec<WidgetConfig>,
}

#[derive(Debug, Clone, serde::Deserialize)]
struct WidgetConfig {
    module: String,
    #[serde(default)]
    x: i32,
    #[serde(default)]
    y: i32,
    #[serde(default = "default_dimension")]
    w: u32,
    #[serde(default = "default_dimension")]
    h: u32,
    update_interval: Option<u64>,
    opts: Option<serde_json::Value>,
}

fn default_dimension() -> u32 { 100 }

fn parse_pages_config(lua_source: &str) -> Result<Vec<Page>> {
    let mut lua = Lua::full();

    let stashed_executor: StashedExecutor = lua.try_enter(|ctx| {
        let closure = Closure::load(ctx, Some("pages.lua".into()), lua_source.as_bytes())
            .map_err(|e| anyhow::anyhow!("Failed to compile pages.lua: {:?}", e))?;
        let executor = Executor::start(ctx, closure.into(), ());
        Ok(ctx.stash(executor))
    })?;

    let json_string: String = lua.enter(|ctx| {
        let executor = ctx.fetch(&stashed_executor);
        let mut fuel = piccolo::Fuel::with(1000000);
        
        while !executor.step(ctx, &mut fuel) {
            if fuel.remaining() <= 0 {
                return "{}".to_string();
            }
        }
        
        let result = executor.take_result::<Value>(ctx);
        
        match result {
            Ok(Ok(Value::Table(t))) => {
                let json = table_to_json(ctx, t);
                serde_json::to_string(&json).unwrap_or_else(|_| "{}".to_string())
            }
            _ => "{}".to_string(),
        }
    });
    
    if json_string == "{}" {
        return Err(anyhow::anyhow!("pages.lua did not return a valid table"));
    }

    let config: PagesConfig = serde_json::from_str(&json_string)
        .with_context(|| format!("Failed to parse pages config: {}", json_string))?;

    let pages = config.pages.into_iter().map(|p| {
        let mut page = Page::new(&p.id, p.title.as_deref().unwrap_or(&p.id));
        if let Some(bg) = p.background {
            page = page.with_background(&bg);
        }
        for w in p.widgets {
            let module_name = w.module.strip_prefix("widgets.").unwrap_or(&w.module);
            let mut widget = WidgetInstance::new(module_name, w.x, w.y, w.w, w.h)
                .with_update_interval(w.update_interval.unwrap_or(1000));
            if let Some(opts) = w.opts {
                widget.context.opts = opts.as_object()
                    .map(|o| o.iter().map(|(k, v)| (k.clone(), v.clone())).collect())
                    .unwrap_or_default();
            }
            page = page.with_widget(widget);
        }
        page
    }).collect();

    Ok(pages)
}

fn table_to_json<'gc>(ctx: piccolo::Context<'gc>, table: Table<'gc>) -> serde_json::Value {
    let first_val = table.get_value(Value::Integer(1));
    if !matches!(first_val, Value::Nil) {
        let mut arr = Vec::new();
        let mut idx = 1i64;
        loop {
            let v = table.get_value(Value::Integer(idx));
            if matches!(v, Value::Nil) {
                break;
            }
            arr.push(value_to_json(ctx, v));
            idx += 1;
        }
        serde_json::Value::Array(arr)
    } else {
        let mut map = serde_json::Map::new();
        for (k, v) in table.iter() {
            if let Value::String(ks) = k {
                if let Ok(key_str) = ks.to_str() {
                    map.insert(key_str.to_string(), value_to_json(ctx, v));
                }
            }
        }
        serde_json::Value::Object(map)
    }
}

fn value_to_json<'gc>(ctx: piccolo::Context<'gc>, value: Value<'gc>) -> serde_json::Value {
    match value {
        Value::Nil => serde_json::Value::Null,
        Value::Boolean(b) => serde_json::Value::Bool(b),
        Value::Integer(i) => serde_json::json!(i),
        Value::Number(n) => serde_json::json!(n),
        Value::String(s) => {
            s.to_str()
                .map(|s| serde_json::Value::String(s.to_string()))
                .unwrap_or(serde_json::Value::Null)
        }
        Value::Table(t) => table_to_json(ctx, t),
        _ => serde_json::Value::Null,
    }
}

fn create_demo_pages() -> Vec<Page> {
    vec![
        Page::new("home", "Home")
            .with_background("#0D3311")
            .with_widget(
                WidgetInstance::new("clock", 20, 20, 360, 180)
                    .with_update_interval(1000),
            )
            .with_widget(
                WidgetInstance::new("status", 400, 20, 380, 180)
                    .with_update_interval(1000),
            )
            .with_widget(
                WidgetInstance::new("quote", 20, 250, 360, 180)
                    .with_update_interval(1000),
            ),
        Page::new("info", "System Info")
            .with_background("#0D3311")
            .with_widget(
                WidgetInstance::new("sysinfo", 20, 20, 760, 420)
                    .with_update_interval(2000),
            ),
    ]
}

impl Default for LuaRuntime {
    fn default() -> Self {
        Self::new().expect("Failed to create Lua runtime")
    }
}
