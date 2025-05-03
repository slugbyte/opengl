const Point = @This();

x: f32 = 0.0,
y: f32 = 0.0,

pub fn init(x: f32, y: f32) Point {
    return Point{
        .x = x,
        .y = y,
    };
}

pub fn add(self: *Point, point: Point) void {
    self.x += point.x;
    self.y += point.y;
}

pub fn subtract(self: *Point, point: Point) void {
    self.x -= point.x;
    self.y -= point.y;
}

pub fn min(self: *Point) f32 {
    if (self.x < self.y) {
        return self.x;
    }
    return self.y;
}

pub fn max(self: *Point) f32 {
    if (self.x > self.y) {
        return self.x;
    }
    return self.y;
}

pub fn scale(self: *Point, scaler: f32) void {
    self.x *= scaler;
    self.y *= scaler;
}
