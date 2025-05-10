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
    var slider_r: f32 = 0.0;
    var slider_g: f32 = 0.0;
    var slider_b: f32 = 0.0;
    var pallet_item_selected: usize = 8;

    var pallet_color_list: [8]Color = [1]Color{Color.gray(150, 255)} ** 8;

    while (window.should_render()) {
        window.frame_begin();
        { // gui
            gui.begin(window.mouse);
            defer gui.end();

            var app = try gui.box(@src(), .{
                .name = "screen",
                .rect = Rect.from(0, 0, window.size.width, window.size.height),
                .color = Color.gray(140, 255),
                .padding = 15,
                .cursor_spacing = 15,
                .cursor_direction = .Horizontal,
            });

            var color_picker = try gui.box(@src(), .{
                .name = "color_picker",
                .rect = app.next_from(app.scale_cw(0.1), 90),
                .cursor_spacing = 15,
                .cursor_direction = .Vertical,
            });

            const prev_r = slider_r;
            slider_r = try gui.slider(@src(), slider_r, .{}, .{
                .rect = color_picker.next_fill(20),
                .color = Color.Red,
                .border_size = 5,
                .border_color = Color.White,
            });
            const prev_g = slider_g;
            slider_g = try gui.slider(@src(), slider_g, .{}, .{
                .rect = color_picker.next_fill(20),
                .color = Color.Green,
                .border_size = 5,
                .border_color = Color.White,
            });
            const prev_b = slider_g;
            slider_b = try gui.slider(@src(), slider_b, .{}, .{
                .rect = color_picker.next_fill(20),
                .color = Color.Blue,
                .border_size = 5,
                .border_color = Color.White,
            });
            if (prev_r != slider_r or prev_g != slider_g or prev_b != slider_b) {
                pallet_item_selected = 8;
            }

            const color = Color.init_float(slider_r, slider_g, slider_b, 1.0);
            _ = try gui.box(@src(), .{
                .name = "color_value",
                .rect = color_picker.next_from(color_picker.size.width, color_picker.size.width),
                .color = color,
                .border_size = 5,
                .border_color = color,
            });

            var pallet = try gui.box(@src(), .{
                .name = "color_value",
                .rect = color_picker.next(Size.init(color_picker.size.width, 50)),
                .cursor_spacing = 5,
            });
            pallet.space_x(-5);

            for (0..8) |i| {
                if (i == 4) {
                    pallet.cursor_reset();
                    pallet.space_x(-5);
                    pallet.space_y(pallet.scale_h(0.5) + 5);
                }

                const pallet_item_rect = pallet.next_from((pallet.content_size.width - 5) / 4, pallet.scale_ch(0.5));
                const pallet_item_color = pallet_color_list[i];

                switch (try gui.button(@src(), .{
                    .item_index = i,
                    .rect = pallet_item_rect,
                    .color = pallet_item_color,
                    .border_size = if (pallet_item_selected == i) 5 else 0,
                    .pallet = .{
                        .bg_default = pallet_item_color,
                        .bg_hot = pallet_item_color,
                        .bg_active = pallet_item_color,
                        .border_default = Color.Black,
                        .border_hot = Color.Black,
                        .border_active = Color.White,
                    },
                })) {
                    .LeftClick => {
                        std.debug.print("pallet: {}", .{i});
                        pallet_item_selected = i;
                        const float_color = pallet_item_color.to_float();
                        slider_r = float_color.r;
                        slider_g = float_color.g;
                        slider_b = float_color.b;
                    },
                    .RightClick => {
                        std.debug.print("pallet: {}", .{i});
                        pallet_color_list[i] = color;
                    },
                    .None => {},
                }
            }
        }
        window.frame_end();
    }

    debug.clear();
    std.debug.print("bye!", .{});
}
