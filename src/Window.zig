const std = @import("std");
const Size = @import("./Size.zig");
const Vec = @import("./Vec.zig");
const Mouse = @import("./Mouse.zig");
const c = @import("./c.zig");

pub const Error = error{
    GLFWInitFailed,
    GLFWCreateWindowFailed,
};

pub var glfw_window: ?*c.GLFWwindow = undefined;
pub var size: Size = undefined;
pub var has_resized: bool = false;
pub var mouse: Mouse = Mouse{};
pub var time_delta: f32 = 0;
pub var time_last: f32 = 0;

pub const WindowOptions = struct {
    size: Size = Size.init(800, 600),
    vsync: bool = true,
    opengl_version_major: c_int = 3,
    opengl_version_minor: c_int = 3,
};

pub const MouseButton = enum(c_int) {
    Left = c.GLFW_MOUSE_BUTTON_LEFT,
    Right = c.GLFW_MOUSE_BUTTON_RIGHT,
    Middel = c.GLFW_MOUSE_BUTTON_MIDDLE,
};

pub const MouseButtonAction = enum(c_int) {
    Press = c.GLFW_PRESS,
    Release = c.GLFW_RELEASE,
};

pub fn init(title: []const u8, opt: WindowOptions) !void {
    if (c.glfwInit() == c.GLFW_FALSE) {
        return Error.GLFWInitFailed;
    }
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, opt.opengl_version_major);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, opt.opengl_version_minor);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    glfw_window = c.glfwCreateWindow(@intFromFloat(opt.size.width), @intFromFloat(opt.size.height), @ptrCast(title.ptr), null, null);
    if (glfw_window == null) {
        return Error.GLFWCreateWindowFailed;
    }
    size = opt.size;
    c.glfwMakeContextCurrent(glfw_window);
    c.glfwSwapInterval(if (opt.vsync) 1 else 0);

    _ = c.glfwSetFramebufferSizeCallback(glfw_window, glfw_callback_framebuffer_resize);
    _ = c.glfwSetCursorPosCallback(glfw_window, glfw_callback_mouse_position);
    _ = c.glfwSetMouseButtonCallback(glfw_window, glfw_callback_mouse_button);

    // TODO: ?? make stb wrapper :)
    c.stbi_set_flip_vertically_on_load(1);
}

pub fn deinit() void {
    c.glfwDestroyWindow(glfw_window);
    c.glfwTerminate();
}

pub fn should_render() bool {
    return c.glfwWindowShouldClose(glfw_window) != c.GLFW_TRUE;
}

pub fn frame_begin() void {
    const time_current: f32 = @as(f32, @floatCast(c.glfwGetTime())) * 1000.0;
    time_delta = time_current - time_last;
    time_last = time_current;
    return c.glfwPollEvents();
}

pub fn frame_end() void {
    has_resized = false;
    mouse.update_end();
    c.glfwSwapBuffers(glfw_window);
}

fn glfw_callback_framebuffer_resize(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
    has_resized = true;
    size = Size{
        .width = @floatFromInt(width),
        .height = @floatFromInt(height),
    };
}

fn glfw_callback_mouse_position(_: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
    mouse.pos = Vec{
        .x = @floatCast(x),
        .y = @floatCast(y),
    };
}

fn glfw_callback_mouse_button(_: ?*c.GLFWwindow, button: c_int, action: c_int, _: c_int) callconv(.C) void {
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
