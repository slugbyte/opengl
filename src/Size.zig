const Size = @This();

width: f32,
height: f32,

pub fn init(width: f32, height: f32) Size {
    return Size{
        .width = width,
        .height = height,
    };
}

pub fn copy(self: Size) Size {
    return Size{
        .width = self.width,
        .height = self.height,
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

pub fn add_width(self: Size, value: f32) Size {
    return Size{
        .width = self.width + value,
        .height = self.height,
    };
}

pub fn add_height(self: Size, value: f32) Size {
    return Size{
        .height = self.height + value,
        .width = self.width,
    };
}

pub fn sub(self: Size, size: Size) Size {
    return Size{
        .width = self.width - size.width,
        .height = self.height - size.height,
    };
}

pub fn sub_value(self: Size, value: f32) Size {
    return Size{
        .width = self.width - value,
        .height = self.height - value,
    };
}

pub fn sub_width(self: Size, value: f32) Size {
    return Size{
        .width = self.width - value,
        .height = self.height,
    };
}

pub fn sub_height(self: Size, value: f32) Size {
    return Size{
        .height = self.height - value,
        .width = self.width,
    };
}
