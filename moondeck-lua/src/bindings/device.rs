use anyhow::Result;
use piccolo::{Callback, CallbackReturn, Lua, Table};
use std::sync::RwLock;
use std::time::{SystemTime, UNIX_EPOCH};

// Global WiFi state (updated by main app)
static WIFI_CONNECTED: RwLock<bool> = RwLock::new(false);
static WIFI_SSID: RwLock<String> = RwLock::new(String::new());
static WIFI_IP: RwLock<String> = RwLock::new(String::new());
static WIFI_RSSI: RwLock<i32> = RwLock::new(-100);

// System info state
static FREE_HEAP: RwLock<u32> = RwLock::new(0);
static CPU_FREQ: RwLock<u32> = RwLock::new(240);
static BOOT_TIME: RwLock<u64> = RwLock::new(0);

/// Update WiFi state from the main application
pub fn set_wifi_status(connected: bool, ssid: &str, ip: &str, rssi: i32) {
    *WIFI_CONNECTED.write().unwrap() = connected;
    *WIFI_SSID.write().unwrap() = ssid.to_string();
    *WIFI_IP.write().unwrap() = ip.to_string();
    *WIFI_RSSI.write().unwrap() = rssi;
}

/// Update system info from the main application
pub fn set_system_info(free_heap: u32, cpu_freq: u32) {
    *FREE_HEAP.write().unwrap() = free_heap;
    *CPU_FREQ.write().unwrap() = cpu_freq;
}

/// Initialize boot time (call once at startup)
pub fn init_boot_time() {
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    *BOOT_TIME.write().unwrap() = now;
}

pub fn register_device(lua: &mut Lua) -> Result<()> {
    // Initialize boot time on first registration
    {
        let boot = BOOT_TIME.read().unwrap();
        if *boot == 0 {
            drop(boot);
            init_boot_time();
        }
    }

    lua.try_enter(|ctx| {
        let device_table = Table::new(&ctx);

        // device.seconds() -> current unix timestamp in seconds
        device_table.set(
            ctx,
            "seconds",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let secs = SystemTime::now()
                    .duration_since(UNIX_EPOCH)
                    .map(|d| d.as_secs() as i64)
                    .unwrap_or(0);
                stack.replace(ctx, secs);
                Ok(CallbackReturn::Return)
            }),
        )?;

        // device.millis() -> current unix timestamp in milliseconds
        device_table.set(
            ctx,
            "millis",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let millis = SystemTime::now()
                    .duration_since(UNIX_EPOCH)
                    .map(|d| d.as_millis() as i64)
                    .unwrap_or(0);
                stack.replace(ctx, millis);
                Ok(CallbackReturn::Return)
            }),
        )?;

        // device.uptime() -> seconds since boot
        device_table.set(
            ctx,
            "uptime",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let boot_time = *BOOT_TIME.read().unwrap();
                let now = SystemTime::now()
                    .duration_since(UNIX_EPOCH)
                    .map(|d| d.as_secs())
                    .unwrap_or(0);
                let uptime = now.saturating_sub(boot_time) as i64;
                stack.replace(ctx, uptime);
                Ok(CallbackReturn::Return)
            }),
        )?;

        // device.wifi_connected() -> bool
        device_table.set(
            ctx,
            "wifi_connected",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let connected = *WIFI_CONNECTED.read().unwrap();
                stack.replace(ctx, connected);
                Ok(CallbackReturn::Return)
            }),
        )?;

        // device.wifi_ssid() -> string
        device_table.set(
            ctx,
            "wifi_ssid",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let ssid = WIFI_SSID.read().unwrap().clone();
                stack.replace(ctx, ctx.intern(ssid.as_bytes()));
                Ok(CallbackReturn::Return)
            }),
        )?;

        // device.ip_address() -> string
        device_table.set(
            ctx,
            "ip_address",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let ip = WIFI_IP.read().unwrap().clone();
                if ip.is_empty() {
                    stack.replace(ctx, ctx.intern(b"Not connected"));
                } else {
                    stack.replace(ctx, ctx.intern(ip.as_bytes()));
                }
                Ok(CallbackReturn::Return)
            }),
        )?;

        // device.wifi_rssi() -> integer (dBm)
        device_table.set(
            ctx,
            "wifi_rssi",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let rssi = *WIFI_RSSI.read().unwrap() as i64;
                stack.replace(ctx, rssi);
                Ok(CallbackReturn::Return)
            }),
        )?;

        // device.free_heap() -> integer (bytes)
        device_table.set(
            ctx,
            "free_heap",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let heap = *FREE_HEAP.read().unwrap() as i64;
                stack.replace(ctx, heap);
                Ok(CallbackReturn::Return)
            }),
        )?;

        // device.cpu_freq() -> integer (MHz)
        device_table.set(
            ctx,
            "cpu_freq",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let freq = *CPU_FREQ.read().unwrap() as i64;
                stack.replace(ctx, freq);
                Ok(CallbackReturn::Return)
            }),
        )?;

        ctx.set_global("device", device_table)?;
        Ok(())
    })?;

    Ok(())
}
