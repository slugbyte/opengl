const std = @import("std");
const c = @import("./c.zig");
const debug = @import("./debug.zig");

const Renderer = @import("./Renderer.zig");

pub var prng: std.Random.Xoshiro256 = undefined;
pub var rand: std.Random = undefined;

pub var renderer: Renderer = undefined;

pub var window_width: c_int = 0;
pub var window_height: c_int = 0;
pub var window_has_resized: bool = false;

pub var time_last: i32 = 0;
pub var time_delta: i32 = 0;

pub var mouse_x: i32 = 0;
pub var mouse_y: i32 = 0;

pub fn debug_print() void {
    debug.hud_start();
    debug.hud_println("time_delta: {d:>4}ms", .{time_delta});
    debug.hud_println("mouse: {d:>5}x {d:>5}y", .{ mouse_x, mouse_y });
    debug.hud_println("window size {d:>5}w {d:>5}h", .{ window_width, window_height });
    debug.hud_end();
}

pub fn time_update() void {
    const time_current: i32 = @intFromFloat(c.glfwGetTime() * 1000.0);
    time_delta = time_current - time_last;
    time_last = time_current;
}

pub fn init(allocator: std.mem.Allocator) !void {
    renderer = try Renderer.init(allocator);
    prng = std.Random.DefaultPrng.init(100);
    rand = prng.random();
}
