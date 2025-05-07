// ! By convention, main.zig is where your main function lives in the case that
// ! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const c = @import("./c.zig");
const debug = @import("./debug.zig");
const config = @import("config");
const window = @import("./Window.zig");

const gl = @import("./gl.zig");
const Shader = @import("./Shader.zig");
const Framebuffer = @import("./Framebuffer.zig");
const Texture = @import("./Texture.zig");
const Color = @import("./Color.zig");
const Dot = @import("./Dot.zig");
const Vec = @import("./Vec.zig");
const Size = @import("./Size.zig");
const Rect = @import("./Rect.zig");
const gui = @import("gui.zig");

const IMAGE_BING = @embedFile("./asset/bing.jpg");

var button_state: i32 = 0;

fn inc_button(src: std.builtin.SourceLocation, value: *f32, inc: f32, pos: Vec, size: Size) !void {
    if (try gui.button_rect(src, Rect.init_point_size(pos, size), .{ .color_default = Color.Green })) {
        value.* += inc;
        value.* = std.math.clamp(value.*, 0, window.size.width);
    }
}

pub fn main() !void {
    std.debug.print("All your pixels are blong to us!\n", .{});

    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();

    try window.init("DEMO", .{});
    defer window.deinit();

    try gl.init(allocator);
    defer gl.deinit();

    var dot_list = std.ArrayList(Dot).init(allocator);
    for (1..100) |_| {
        try dot_list.append(Dot.init());
    }
    const color_bg = Color.gray(25, 255);

    // image_texture
    var image_texure = Texture.init_with_image_data(IMAGE_BING, .T4);
    defer image_texure.deinit();

    // setup framebuffer and texture for drawing background
    var bg_texture = Texture.init(window.size.width, window.size.height, .T3);
    defer bg_texture.deinit();
    var bg_framebuffer = try Framebuffer.init();
    bg_framebuffer.bind();
    bg_framebuffer.texture_attach(bg_texture, .A0);
    try bg_framebuffer.status_check();
    gl.clear(color_bg);
    bg_framebuffer.bind_zero();

    // setup button
    // var button = Button.init(100, 100, 100, 50);
    // button.on_click(&button_callback);

    var slider_value: f32 = 0;

    var stack_x_target: f32 = 0;
    var stack_y_target: f32 = 0;
    var stack_x: f32 = stack_x_target;
    var stack_y: f32 = stack_y_target;
    // while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
    while (window.should_render()) {
        window.frame_begin();

        // c.glfwPollEvents();
        // ctx.update_begin();

        gl.clear(Color.Black);
        // TODO: what happens if a new texture gets bound to the texture.unit before the
        // framebuffer is rebound?

        // render background to a texture
        bg_framebuffer.bind();
        if (window.has_resized) {
            try bg_texture.reset(window.size.width, window.size.height);
            gl.clear(color_bg);
        }

        try gl.shader_program_set(.{ .Circle = {} });
        for (dot_list.items) |*dot_item| {
            dot_item.update();
            try dot_item.render();
        }
        try gl.batch.flush();

        try gl.shader_program_set(.{ .Default = {} });
        for (dot_list.items) |*dot_item| {
            dot_item.update();
            try dot_item.render();
        }
        try gl.batch.flush();
        bg_framebuffer.bind_zero();

        bg_texture.bind();
        try gl.shader_program_set(.{ .Texture = bg_texture });
        try gl.batch.draw_rect(0, 0, window.size.width, window.size.height, Color{});
        try gl.batch.flush();

        // image
        try gl.shader_program_set(.{ .Texture = image_texure });
        try gl.draw_rect(Rect.init(600, 700, image_texure.width, image_texure.height), Color{});

        // pallet
        const pallet_x = @divFloor(window.size.width, 2) - 125;
        const pallet_y = @divFloor(window.size.height, 6) - 125;
        try gl.shader_program_set(.{ .Default = {} });
        try gl.batch.draw_rect(pallet_x, pallet_y, 250, 250, Color.Black);
        try gl.batch.draw_rect_color_interploate(pallet_x + 2, pallet_y + 2, 246, 246, Color.White, Color{ .r = 255 }, Color{}, Color.Black);
        try gl.batch.draw_rect(pallet_x, pallet_y + 255, 250, 50, Color{});
        try gl.batch.flush();

        gui.begin(window.mouse);

        if (stack_x != stack_x_target) {
            stack_x = gui.lerp(stack_x, stack_x_target, 0.1);
        }
        if (stack_y != stack_y_target) {
            stack_y = gui.lerp(stack_y, stack_y_target, 0.1);
        }
        var stack_outer = try gui.stack_h(@src(), Vec.init(stack_x, stack_y), Size{ .width = 500, .height = 50 }, Color.Red);
        const stack_inner_size = Size{
            .width = stack_outer.size.width - 20,
            .height = stack_outer.size.height - 20,
        };
        var stack_inner = try gui.stack_h(@src(), Vec.init(stack_x + 10, stack_y + 10), stack_inner_size, Color.Blue);
        stack_inner.cursor.padding = 5;

        var button_size = Size.init(stack_outer.percent_width(0.25), stack_inner.size.height);
        button_size.width -= (stack_inner.cursor.padding * 2);
        try inc_button(@src(), &stack_x_target, -150, stack_inner.next(button_size), button_size);
        try inc_button(@src(), &stack_y_target, 150, stack_inner.next(button_size), button_size);
        try inc_button(@src(), &stack_y_target, -150, stack_inner.next(button_size), button_size);
        try inc_button(@src(), &stack_x_target, 150, stack_inner.next(button_size), button_size);

        stack_outer.end();

        // quit buttn
        if (try gui.button_rect(@src(), Rect.init(window.size.width - 55, 5, 50, 50), .{})) {
            window.close();
        }

        // write png button
        if (try gui.button_rect(@src(), Rect.init(window.size.width - 55, 60, 50, 50), .{})) {
            try bg_texture.write_png(allocator, config.debug_png_out);
            debug.clear();
            std.debug.print("wrote debug_png_out to {s}\n", .{config.debug_png_out});
        }
        slider_value = try gui.slider(@src(), Rect.init(10, (window.size.height / 2) - 100, 50, 200), slider_value);

        gui.end();

        window.frame_end();
    }

    debug.clear();
    std.debug.print("bye!", .{});
}
