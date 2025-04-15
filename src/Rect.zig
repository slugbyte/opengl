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

pub fn is_inside(self: *Rect, x: f32, y: f32) bool {
    const x_max = self.x + self.width;
    const y_max = self.y + self.height;
    return x >= self.x and x <= x_max and y >= self.y and y <= y_max;
}
