const std = @import("std");
const c = @import("./c.zig");
const debug = @import("./debug.zig");
const Mouse = @import("./Mouse.zig");
const Vec = @import("./Vec.zig");

const fnv = std.hash.Fnv1a_32;

pub var prng: std.Random.Xoshiro256 = undefined;
pub var rand: std.Random = undefined;

pub var time_last: f32 = 0;
pub var time_delta: f32 = 0;

pub var fps: f32 = 60;

// pub var mouse: Mouse = Mouse{};

pub fn init() !void {
    prng = std.Random.DefaultPrng.init(100);
    rand = prng.random();
}

pub fn update_begin() void {
    time_update();
}

pub fn update_end() void {
    // window_has_resized = false;
    // mouse.update_end();
}

// generate a random i32 between range and cast it as a float
pub fn random(min: f32, max: f32) f32 {
    return @floatFromInt(rand.intRangeLessThan(i32, @intFromFloat(min), @intFromFloat(max)));
}

pub fn inspect(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt, args);
    std.debug.print("\n", .{});
}

pub fn info(comptime msg: []const u8) void {
    std.debug.print(msg, .{});
    std.debug.print("\n", .{});
}

pub fn debug_hud_print() void {
    debug.hud_start();
    debug.hud_println("fps: {d:<5}", .{fps});
    // debug.hud_println("{}", .{mouse});
    // debug.hud_println("window size {d:>5}w {d:>5}h", .{ window_width, window_height });
    debug.hud_end();
}

fn fps_update_smoothed() void {
    if (time_delta == 0) {
        return;
    }
    const alpha: f32 = 0.1;
    const current_fps: f32 = 1000.0 / time_delta;
    fps = alpha * current_fps + (1.0 - alpha) * fps;
}

fn time_update() void {
    const time_current: f32 = @as(f32, @floatCast(c.glfwGetTime())) * 1000.0;
    time_delta = time_current - time_last;
    time_last = time_current;
    fps_update_smoothed();
}
