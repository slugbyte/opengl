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
pub var window_has_resized_frame: bool = false;

pub var time_last: f32 = 0;
pub var time_delta: f32 = 0;

pub var frame_last: f32 = 0;
pub var frame_delta: f32 = 0;
pub var frame_update: bool = true;

pub var fps: f32 = 60;

pub var mouse_x: f32 = 0;
pub var mouse_y: f32 = 0;

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

pub fn time_now() f32 {
    return @floatCast(c.glfwGetTime());
}

pub fn time_delta_update() void {
    const time_current: f32 = time_now();
    time_delta = time_current - time_last;
    time_last = time_current;

    frame_update = false;
    frame_delta = time_current - frame_last;
    if ((frame_delta * 1000) > 16.6) {
        frame_last = time_current;
        frame_update = true;
    }
}

pub fn random(min: f32, max: f32) f32 {
    return @floatFromInt(rand.intRangeLessThan(i32, @intFromFloat(min), @intFromFloat(max)));
}

pub fn init(allocator: std.mem.Allocator) !void {
    renderer = try Renderer.init(allocator);
    prng = std.Random.DefaultPrng.init(100);
    rand = prng.random();
}
