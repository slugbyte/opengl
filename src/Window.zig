const std = @import("std");
const Size = @import("./Size.zig");
const Vec = @import("./Vec.zig");
const Mouse = @import("./Mouse.zig");
const c = @import("./c.zig");

pub const Error = error{
    GLFWInitFailed,
    GLFWCreateWindowFailed,
};

pub const Window = @This();

glfw_window: ?*c.GLFWwindow,
size: Size,
has_resized: bool = false,
mouse: Mouse = Mouse{},

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

pub fn init(title: []const u8, opt: WindowOptions) !Window {
    if (c.glfwInit() == c.GLFW_FALSE) {
        return Error.GLFWInitFailed;
    }
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, opt.opengl_version_major);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, opt.opengl_version_minor);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    const window = c.glfwCreateWindow(@intFromFloat(opt.size.width), @intFromFloat(opt.size.height), @ptrCast(title.ptr), null, null);
    if (window == null) {
        return Error.GLFWCreateWindowFailed;
    }

    c.glfwMakeContextCurrent(window);
    c.glfwSwapInterval(if (opt.vsync) 1 else 0);
    var result = Window{
        .size = opt.size,
        .glfw_window = window,
    };

    result.on_resize();

    return result;
}

fn glfw_callback_init(self: *Window) void {
    const callback = struct {
        pub fn framebuffer_resize(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
            self.has_resized = true;
            self.size = Size{
                .width = @floatFromInt(width),
                .height = @floatFromInt(height),
            };
        }
        pub fn mouse_position(_: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
            self.mouse.pos = Vec{
                .x = @floatCast(x),
                .y = @floatCast(y),
            };
        }
        pub fn mouse_button(_: ?*c.GLFWwindow, button: c_int, action: c_int, _: c_int) callconv(.C) void {
            if (button == c.GLFW_MOUSE_BUTTON_LEFT) {
                if (action == c.GLFW_PRESS) {
                    self.mouse.left_pressed = true;
                    self.mouse.left_just_pressed = true;
                }

                if (action == c.GLFW_RELEASE) {
                    self.mouse.left_pressed = false;
                    self.mouse.left_just_released = true;
                }
            }
        }
    };
    c.glfwSetFramebufferSizeCallback(self.glfw_window, callback.framebuffer_resize);
    c.glfwSetCursorPosCallback(self.glfw_window, callback.mouse_position);
    c.glfwSetMouseButtonCallback(self.glfw_window, callback.mouse_button);
}

pub fn deinit(self: Window) void {
    c.glfwDestroyWindow(self.glfw_window);
    c.glfwTerminate();
}

pub fn poll_events(self: Window) void {
    _ = self;
    return c.glfwPollEvents();
}

pub fn should_render(self: Window) bool {
    return c.glfwWindowShouldClose(self.glfw_window) != c.GLFW_TRUE;
}

pub fn swap_buffers(self: Window) void {
    c.glfwSwapBuffers(self.glfw_window);
}

pub fn end_of_frame(self: *Window) void {
    self.has_resized = false;
}
