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

pub fn main() !void {
    std.debug.print("All your pixels are blong to us!\n", .{});

    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();

    try window.init("DEMO", .{ .color_background = Color.Black });
    defer window.deinit();

    try gl.init(allocator);
    defer gl.deinit();

    // var show_border: bool = false;
    while (window.should_render()) {
        window.frame_begin();
        gui.begin(window.mouse);

        // const menu = try gui.box(Vec.init(0, 0), Size.init(window.size.width * 0.25, window.size.height), .{
        var menu = try gui.box(@src(), .{
            .rect = Rect.from(0, 0, window.size.width / 2, window.size.height / 2),
            .color = Color.Blue,
            .padding = 10,
            .spacing = 10,
            .cursor_direction = .Vertical,
            // .cursor_align = .Center,
            .allow_overflow = false,
        });

        _ = try gui.box(@src(), .{
            .rect = menu.next(Size.init(menu.content_size.width, menu.content_size.height / 2 - menu.spacing / 2)),
            .color = Color.White,
        });

        _ = try gui.box(@src(), .{
            .rect = menu.next(Size.init(menu.content_size.width, menu.content_size.height / 2 - menu.spacing / 2)),
            .color = Color.White,
        });

        _ = try gui.box(@src(), .{
            .rect = menu.center_rect(Size.init(300, 300)),
            .color = Color.Black,
        });

        menu.end();

        gui.end();
        window.frame_end();
    }

    debug.clear();
    std.debug.print("bye!", .{});
}
