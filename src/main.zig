const std = @import("std");
const NAME = "bricks";
const raylib = @import("raylib");
pub fn main() !void {
    const screen = struct {
        pub const height: i32 = 450;
        pub const width: i32 = 800;
    };
    raylib.initWindow(screen.width, screen.height, NAME);
    defer raylib.closeWindow();

    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();
        defer raylib.endDrawing();
        raylib.clearBackground(raylib.colors.RayWhite);
    }
}
