const std = @import("std");
const c = @import("./c.zig");
const debug = @import("./debug.zig");

const Renderer = @import("./Renderer.zig");

pub var prng: std.Random.Xoshiro256 = undefined;
pub var rand: std.Random = undefined;

pub var renderer: Renderer = undefined;

pub var window_width: f32 = 0;
pub var window_height: f32 = 0;
pub var window_has_resized: bool = false;

pub var time_last: f32 = 0;
pub var time_delta: f32 = 0;

pub var fps: f32 = 60;

pub var mouse_x: f32 = 0;
pub var mouse_y: f32 = 0;

pub var mouse_left_pressed: bool = false;
pub var mouse_left_just_pressed: bool = false;
pub var mouse_left_just_released: bool = false;

var gui_id_bucket: u32 = 0;

pub fn gui_id() u32 {
    const result = gui_id_bucket;
    gui_id_bucket += 1;
    return result;
}

fn fps_update_smoothed() void {
    if (time_delta == 0) {
        return;
    }
    const alpha: f32 = 0.1;
    const current_fps: f32 = 1000.0 / time_delta;
    fps = alpha * current_fps + (1.0 - alpha) * fps;
}

pub fn debug_print() void {
    debug.hud_start();
    fps_update_smoothed();
    debug.hud_println("fps: {d:<5}", .{fps});
    debug.hud_println("mouse: {d:>5}x {d:>5}y", .{ mouse_x, mouse_y });
    debug.hud_println("window size {d:>5}w {d:>5}h", .{ window_width, window_height });
    debug.hud_end();
}

pub fn time_update() void {
    const time_current: f32 = @as(f32, @floatCast(c.glfwGetTime())) * 1000.0;
    time_delta = time_current - time_last;
    time_last = time_current;
}

pub fn random(min: f32, max: f32) f32 {
    return @floatFromInt(rand.intRangeLessThan(i32, @intFromFloat(min), @intFromFloat(max)));
}

pub fn init(allocator: std.mem.Allocator) !void {
    renderer = try Renderer.init(allocator);
    prng = std.Random.DefaultPrng.init(100);
    rand = prng.random();
}
