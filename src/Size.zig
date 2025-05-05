const Size = @This();

width: f32,
height: f32,

pub fn init(width: f32, height: f32) Size {
    return Size{
        .width = width,
        .height = height,
    };
}
