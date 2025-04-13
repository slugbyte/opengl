//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const c = @import("./c.zig");
const ctx = @import("./context.zig");

const Renderer = @import("./Renderer.zig");
const Shader = @import("./Shader.zig");
const Color = @import("./Color.zig");
const Dot = @import("./Dot.zig");

const shader_vertex_source = @embedFile("./shader/vertex.glsl");
const shader_fragment_default_source = @embedFile("./shader/fragment_default.glsl");
const shader_fragment_circle_source = @embedFile("./shader/fragment_circle.glsl");
const shader_fragment_texture_source = @embedFile("./shader/fragment_texture.glsl");
// 1) create a triangle using pixelspace that is solid color
// 2) make a gradient using vector interpolation

fn callback_framebuffer_resize(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
    ctx.window_width = width;
    ctx.window_height = height;
    ctx.window_has_resized = true;
}

fn callback_cursor_position(_: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
    ctx.mouse_x = @intFromFloat(x);
    ctx.mouse_y = @intFromFloat(y);
}

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();

    if (c.glfwInit() == c.GLFW_FALSE) {
        @panic("failed to init glfw");
    }
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    const window = c.glfwCreateWindow(800, 600, "EMO", null, null);
    if (window == null) {
        @panic("glfw failed to create window");
    }
    c.glfwMakeContextCurrent(window);
    try ctx.init(allocator);
    // var ctx.rand: std.Random = undefined;
    // var prng = std.Random.DefaultPrng.init(100);
    // ctx.rand = prng.ctx.random();
    callback_framebuffer_resize(window, 800, 600);
    _ = c.glfwSetFramebufferSizeCallback(window, &callback_framebuffer_resize);
    _ = c.glfwSetCursorPosCallback(window, &callback_cursor_position);

    var dot_list = std.ArrayList(Dot).init(allocator);

    for (1..100) |_| {
        try dot_list.append(Dot.init());
    }

    var shader_default = try Shader.init(.Circle, shader_vertex_source, shader_fragment_default_source);
    defer shader_default.deinit();
    var shader_circle = try Shader.init(.Circle, shader_vertex_source, shader_fragment_circle_source);
    defer shader_circle.deinit();
    var shader_texture = try Shader.init(.Circle, shader_vertex_source, shader_fragment_texture_source);
    defer shader_texture.deinit();

    const color_bg = Color.gray(25, 255);
    // const color_fg = Color.gray(240, 255);
    //
    var fbo: c_uint = undefined;
    c.glGenFramebuffers(1, &fbo);
    c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);

    var tex: c_uint = undefined;
    c.glGenTextures(1, &tex);
    c.glBindTexture(c.GL_TEXTURE_2D, tex);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGB, ctx.window_width, ctx.window_height, 0, c.GL_RGB, c.GL_UNSIGNED_BYTE, null);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    c.glFramebufferTexture2D(c.GL_FRAMEBUFFER, c.GL_COLOR_ATTACHMENT0, c.GL_TEXTURE_2D, tex, 0);

    if (c.glCheckFramebufferStatus(c.GL_FRAMEBUFFER) != c.GL_FRAMEBUFFER_COMPLETE) {
        @panic("framebuffer is not complete");
    }
    ctx.renderer.clear(color_bg);
    c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

    while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        ctx.time_update();
        ctx.renderer.clear(color_bg);

        // render background to a texture
        c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
        ctx.renderer.blend_enable_alpha();
        if (ctx.window_has_resized) {
            c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGB, ctx.window_width, ctx.window_height, 0, c.GL_RGB, c.GL_UNSIGNED_BYTE, null);
            ctx.renderer.clear(color_bg);
        }

        try ctx.renderer.begin(shader_circle);
        for (dot_list.items) |*dot_item| {
            dot_item.update();
            try dot_item.render();
        }
        try ctx.renderer.end();
        try ctx.renderer.begin(shader_default);
        for (dot_list.items) |*dot_item| {
            dot_item.update();
            try dot_item.render();
        }
        try ctx.renderer.end();
        c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

        // render background texture to framebuffer
        try ctx.renderer.begin(shader_texture);
        try shader_texture.u_texture_set(0);
        try ctx.renderer.draw_rect(0, 0, ctx.window_width, ctx.window_height, Color{});
        try ctx.renderer.end();

        // pallet
        ctx.renderer.blend_disable();
        const pallet_x = @divFloor(ctx.window_width, 2) - 125;
        const pallet_y = @divFloor(ctx.window_height, 6) - 125;
        try ctx.renderer.begin(shader_default);
        try ctx.renderer.draw_rect(pallet_x, pallet_y, 250, 250, Color.Black);
        try ctx.renderer.draw_rect_color_interploate(pallet_x + 2, pallet_y + 2, 246, 246, Color.White, Color{ .r = 255 }, Color{}, Color.Black);
        try ctx.renderer.draw_rect(pallet_x, pallet_y + 255, 250, 50, Color{});
        try ctx.renderer.end();

        ctx.window_has_resized = false;

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
        ctx.debug_print();
    }
}
