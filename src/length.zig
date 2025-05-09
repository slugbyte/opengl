const std = @import("std");

pub const Length = union(enum) {
    Pixel: f32,
    Scale: f32,
    pub fn format(self: Length, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        switch (self) {
            .Pixel => |val| {
                try writer.print("Length({d}px)", .{val});
            },
            .Scale => |val| {
                try writer.print("Length({d}%)", .{val});
            },
        }
    }
};

pub fn pixel(val: f32) Length {
    return .{ .Pixel = val };
}

pub fn scale(val: f32) Length {
    return .{ .Scale = val };
}
