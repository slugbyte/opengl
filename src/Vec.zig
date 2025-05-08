const std = @import("std");
const Vec = @This();

x: f32 = 0.0,
y: f32 = 0.0,

pub fn init(x: f32, y: f32) Vec {
    return Vec{
        .x = x,
        .y = y,
    };
}

pub fn copy(self: Vec) Vec {
    return Vec{
        .x = self.x,
        .y = self.y,
    };
}

pub fn add(self: Vec, vec: Vec) Vec {
    return Vec{
        .x = self.x + vec.x,
        .y = self.y + vec.y,
    };
}

pub fn add_value(self: Vec, value: f32) Vec {
    return Vec{
        .x = self.x + value,
        .y = self.y + value,
    };
}

pub fn add_x(self: Vec, x: f32) Vec {
    return Vec{
        .x = self.x + x,
        .y = self.y,
    };
}

pub fn add_y(self: Vec, y: f32) Vec {
    return Vec{
        .y = self.y + y,
        .x = self.x,
    };
}

pub fn sub(self: Vec, vec: Vec) Vec {
    return Vec{
        .x = self.x - vec.x,
        .y = self.y - vec.y,
    };
}

pub fn sub_x(self: Vec, x: f32) Vec {
    return Vec{
        .x = self.x - x,
        .y = self.y,
    };
}

pub fn sub_y(self: Vec, y: f32) Vec {
    return Vec{
        .y = self.y - y,
        .x = self.x,
    };
}

pub fn scale(self: Vec, scaler: f32) Vec {
    return Vec{
        .x = self.x * scaler,
        .y = self.y * scaler,
    };
}

pub fn scale_x(self: Vec, scaler: f32) Vec {
    return Vec{
        .x = self.x * scaler,
        .y = self.y,
    };
}

pub fn scale_y(self: Vec, scaler: f32) Vec {
    return Vec{
        .y = self.y * scaler,
        .x = self.x,
    };
}

pub fn min(self: Vec) f32 {
    if (self.x < self.y) {
        return self.x;
    }
    return self.y;
}

pub fn max(self: Vec) f32 {
    if (self.x > self.y) {
        return self.x;
    }
    return self.y;
}

pub fn format(self: Vec, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;

    try writer.print("Vec(x={d} y={d})", .{ self.x, self.y });
}
