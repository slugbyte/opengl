const Point = @import("./Point.zig");
const Rect = @This();

x: f32,
y: f32,
width: f32,
height: f32,

pub fn init(x: f32, y: f32, width: f32, height: f32) Rect {
    return Rect{
        .x = x,
        .y = y,
        .width = width,
        .height = height,
    };
}

pub fn contians(self: Rect, point: Point) bool {
    const x_max = self.x + self.width;
    const y_max = self.y + self.height;
    return point.x >= self.x and point.x <= x_max and point.y >= self.y and point.y <= y_max;
}

// pub fn contains(self: *Rect, point: Point) bool {
//     return is_inside(self, point.x, point.y);
// }
