const std = @import("std");
const buildin = @import("builtin");
const NAME = "bricks";
const raylib = @import("raylib");
const Red = raylib.colors.Red;
const Rectangle = raylib.Rectangle;
const Vector2 = raylib.Vector2;
const Player = struct {
    pos: Vector2,
    size: Vector2,
    speed: f32,
};
const Bullet = struct {
    pos: Vector2,
    active: bool = false,
};
const Brick = struct {
    pos: Vector2,
    active: bool = false,
};
const MAX_BULLETS: usize = 8;
const MAX_BRICKS: usize = 3;
const FPS: i32 = 60;
pub fn main() !void {
    const screen = struct {
        pub const width: i32 = 800;
        pub const height: i32 = 450;
    };

    const message = "Bullets: {d}/8";
    const message_buff = blk: {
        const bufflen = std.fmt.count(message, .{MAX_BULLETS}) + 1;
        const buf = try std.heap.page_allocator.alloc(u8, @intCast(bufflen));
        break :blk buf;
    };
    defer std.heap.page_allocator.free(message_buff);

    var bullets: [MAX_BULLETS]Bullet = [_]Bullet{.{ .pos = .{ 0, 0 } }} ** MAX_BULLETS;
    var bullet_count: usize = 0;

    var bricks: [MAX_BRICKS]Brick = [_]Brick{.{ .pos = .{ 0, 0 } }} ** MAX_BRICKS;

    var player: Player = .{
        .pos = .{
            (screen.width / 2) - 16,
            screen.height - 16,
        },
        .size = .{ 16, 16 },
        .speed = 7,
    };
    const bullet_speed: f32 = 4;
    raylib.initWindow(screen.width, screen.height, NAME);
    defer raylib.closeWindow();
    raylib.setTargetFps(FPS);
    var frame: i32 = 0;
    var tick: i32 = 0;
    while (!raylib.windowShouldClose()) : (frame += 1) {
        if (@mod(frame, FPS) == 0)
            tick += 1;
        // out of bounds check
        for (&bullets) |*bullet| {
            const min_out: Vector2 = .{ 0, 0 };
            const max_out: Vector2 = .{ screen.width, screen.height };
            const min_ck = bullet.pos < min_out;
            const max_ck = bullet.pos > max_out;
            if (bullet.active and (min_ck[0] or min_ck[1] or max_ck[0] or max_ck[1])) {
                bullet.active = false;
                bullet_count -= 1;
            }
        }
        // Player Input
        if (raylib.isKeyDown(.Right))
            player.pos[0] += player.speed;
        if (raylib.isKeyDown(.Left))
            player.pos[0] -= player.speed;
        if (raylib.isKeyPressed(.Space) and bullet_count < MAX_BULLETS) {
            const bullet_start_pos: Vector2 = .{ player.pos[0] + 4, player.pos[1] - 4 };
            bullet: for (&bullets) |*bullet| {
                if (bullet.active)
                    continue;
                bullet.active = true;
                bullet_count += 1;
                bullet.pos = bullet_start_pos;
                break :bullet;
            }
        }
        // spawn bricks
        if (tick > 0 and @mod(tick, 3) == 0) {
            tick = 0;
            find_inactive: for (&bricks) |*brick| {
                if (brick.active)
                    continue;
                brick.active = true;
                brick.pos = .{ @floatFromInt(raylib.getRandomValue(0, screen.width)), 0 };
                break :find_inactive;
            }
        }
        // brick movement
        if (@mod(frame, 10) == 0) {
            for (&bricks) |*brick| {
                if (!brick.active)
                    continue;
                brick.pos[1] += 2;
            }
        }
        // bullet movement
        for (&bullets) |*bullet| {
            if (bullet.active)
                bullet.pos[1] -= bullet_speed;
        }
        raylib.beginDrawing();
        defer raylib.endDrawing();
        raylib.clearBackground(raylib.colors.RayWhite);
        raylib.drawRectangleV(player.pos, player.size, Red);
        for (bullets) |bullet|
            if (bullet.active)
                raylib.drawRectangleV(bullet.pos, .{ 8, 8 }, Red);
        for (bricks) |brick|
            if (brick.active)
                raylib.drawRectangleV(brick.pos, .{ 32, 32 }, raylib.colors.Blue);

        raylib.drawText(try std.fmt.bufPrintZ(message_buff, message, .{MAX_BULLETS - bullet_count}), 6, 6, 24, raylib.colors.Black);
    }
}
