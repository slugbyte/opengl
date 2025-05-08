const Size = @This();

width: f32,
height: f32,

pub fn init(width: f32, height: f32) Size {
    return Size{
        .width = width,
        .height = height,
    };
}

pub fn add(self: Size, size: Size) Size {
    return Size{
        .width = self.width + size.width,
        .height = self.height + size.height,
    };
}

pub fn add_value(self: Size, value: f32) Size {
    return Size{
        .width = self.width + value,
        .height = self.height + value,
    };
}
