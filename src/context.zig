const std = @import("std");
const c = @import("./c.zig");
const debug = @import("./debug.zig");
const Mouse = @import("./Mouse.zig");
const Vec = @import("./Vec.zig");

const fnv = std.hash.Fnv1a_32;

pub var prng: std.Random.Xoshiro256 = undefined;
pub var rand: std.Random = undefined;

pub var window_width: f32 = 0;
pub var window_height: f32 = 0;
pub var window_has_resized: bool = false;

pub var time_last: f32 = 0;
pub var time_delta: f32 = 0;

pub var fps: f32 = 60;

pub var mouse: Mouse = Mouse{};

pub fn init() !void {
    prng = std.Random.DefaultPrng.init(100);
    rand = prng.random();
}

pub fn update_begin() void {
    time_update();
}

pub fn update_end() void {
    window_has_resized = false;
    mouse.update_end();
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
    debug.hud_println("{}", .{mouse});
    debug.hud_println("window size {d:>5}w {d:>5}h", .{ window_width, window_height });
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

pub fn glfw_callback_framebuffer_resize(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
    window_width = @floatFromInt(width);
    window_height = @floatFromInt(height);
    window_has_resized = true;
}

pub fn glfw_callback_cursor_position(_: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
    mouse.pos = Vec{
        .x = @floatCast(x),
        .y = @floatCast(y),
    };
}

pub fn glfw_callback_mouse_button(_: ?*c.GLFWwindow, button: c_int, action: c_int, _: c_int) callconv(.C) void {
    if (button == c.GLFW_MOUSE_BUTTON_LEFT) {
        if (action == c.GLFW_PRESS) {
            mouse.left_pressed = true;
            mouse.left_just_pressed = true;
        }

        if (action == c.GLFW_RELEASE) {
            mouse.left_pressed = false;
            mouse.left_just_released = true;
        }
    }
}

pub fn src_to_id(src: std.builtin.SourceLocation, item: ?usize) u32 {
    const _item = item orelse 0;
    var hash = fnv.init();
    hash.update(std.mem.asBytes(&src.file.ptr));
    hash.update(std.mem.asBytes(&src.module.ptr));
    hash.update(std.mem.asBytes(&src.line));
    hash.update(std.mem.asBytes(&src.column));
    hash.update(std.mem.asBytes(&src.column));
    hash.update(std.mem.asBytes(&_item));
    return hash.final();
}
