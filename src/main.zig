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
    hit: bool = false,
};
const Brick = struct {
    pos: Vector2,
    active: bool = false,
    hit: bool = false,
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
    var score_buff: [256]u8 = [_]u8{0} ** 256;
    const message_buff = blk: {
        const bufflen = std.fmt.count(message, .{MAX_BULLETS}) + 1;
        const buf = try std.heap.page_allocator.alloc(u8, @intCast(bufflen));
        break :blk buf;
    };
    defer std.heap.page_allocator.free(message_buff);
    var state: struct {
        score: i32 = 0,
        game_over: bool = false,
        bullets: [MAX_BULLETS]Bullet = [_]Bullet{.{ .pos = .{ 0, 0 } }} ** MAX_BULLETS,
        bullet_count: usize = 0,
        bricks: [MAX_BRICKS]Brick = [_]Brick{.{ .pos = .{ 0, 0 } }} ** MAX_BRICKS,
        player: Player = .{
            .pos = .{
                (screen.width / 2) - 16,
                screen.height - 16,
            },
            .size = .{ 16, 16 },
            .speed = 7,
        },
    } = .{};

    const bullet_speed: f32 = 4;
    const brick_speed: f32 = 2;

    raylib.initWindow(screen.width, screen.height, NAME);
    defer raylib.closeWindow();
    raylib.setTargetFps(FPS);
    const background = raylib.loadRenderTexture(screen.width, screen.height);
    defer raylib.unloadRenderTexture(background);
    var frame: i32 = 0;
    var tick: i32 = 0;
    while (!raylib.windowShouldClose()) : (frame += 1) {
        if (!state.game_over) {
            if (@mod(frame, FPS) == 0)
                tick += 1;
            // out of bounds check
            for (&state.bullets) |*bullet| {
                const min_out: Vector2 = .{ 0, 0 };
                const max_out: Vector2 = .{ screen.width, screen.height };
                const min_ck = bullet.pos < min_out;
                const max_ck = bullet.pos > max_out;
                if (bullet.active and (min_ck[0] or min_ck[1] or max_ck[0] or max_ck[1])) {
                    bullet.active = false;
                    state.bullet_count -= 1;
                }
            }

            // Remove hit objects
            for (&state.bullets) |*bullet| {
                if (bullet.active and bullet.hit) {
                    bullet.active = false;
                    bullet.hit = false;
                    state.bullet_count -= 1;
                }
            }
            for (&state.bricks) |*brick| {
                if (brick.active and brick.hit) {
                    brick.active = false;
                    brick.hit = false;
                    state.score += 5;
                }
            }

            // Player Input
            if (raylib.isKeyDown(.Right))
                state.player.pos[0] += state.player.speed;
            if (raylib.isKeyDown(.Left))
                state.player.pos[0] -= state.player.speed;
            if (raylib.isKeyPressed(.Space) and state.bullet_count < MAX_BULLETS) {
                const bullet_start_pos: Vector2 = .{ state.player.pos[0] + 4, state.player.pos[1] - 4 };
                bullet: for (&state.bullets) |*bullet| {
                    if (bullet.active)
                        continue;
                    bullet.active = true;
                    state.bullet_count += 1;
                    bullet.pos = bullet_start_pos;
                    break :bullet;
                }
            }
            // spawn bricks
            if (tick > 0 and @mod(tick, 3) == 0) {
                tick = 0;
                find_inactive: for (&state.bricks) |*brick| {
                    if (brick.active)
                        continue;
                    brick.active = true;
                    brick.pos = .{ @floatFromInt(raylib.getRandomValue(0, screen.width)), 0 };
                    break :find_inactive;
                }
            }
            // brick movement
            if (@mod(frame, 10) == 0) {
                for (&state.bricks) |*brick| {
                    if (!brick.active)
                        continue;
                    brick.pos[1] += brick_speed;
                }
            }
            // bullet movement
            for (&state.bullets) |*bullet| {
                if (bullet.active)
                    bullet.pos[1] -= bullet_speed;
            }

            // Check for collisions
            collision: for (&state.bricks) |*brick| {
                if (!brick.active)
                    continue :collision;
                const brick_rec: Rectangle = .{
                    .x = brick.pos[0],
                    .y = brick.pos[1],
                    .height = 32,
                    .width = 32,
                };
                bullet: for (&state.bullets) |*bullet| {
                    if (!bullet.active)
                        continue :bullet;
                    const bullet_rec: Rectangle = .{
                        .x = bullet.pos[0],
                        .y = bullet.pos[1],
                        .width = 8,
                        .height = 8,
                    };
                    if (raylib.checkCollisionRecs(brick_rec, bullet_rec)) {
                        brick.hit = true;
                        bullet.hit = true;
                    }
                }
                if (brick.hit)
                    continue :collision;
                if (brick.pos[1] + 32 > screen.height)
                    state.game_over = true;
            }
        }

        // Reset game
        if (state.game_over and raylib.isKeyPressed(.Space))
            state = .{};

        // Render objects
        if (!state.game_over) {
            raylib.beginTextureMode(background);
            defer raylib.endTextureMode();

            raylib.clearBackground(raylib.colors.Blank);
            raylib.drawRectangleV(state.player.pos, state.player.size, Red);

            for (state.bullets) |bullet|
                if (bullet.active)
                    raylib.drawRectangleV(bullet.pos, .{ 8, 8 }, Red);
            for (state.bricks) |brick|
                if (brick.active)
                    raylib.drawRectangleV(brick.pos, .{ 32, 32 }, raylib.colors.Blue);

            raylib.drawText(try std.fmt.bufPrintZ(message_buff, message, .{MAX_BULLETS - state.bullet_count}), 6, 6, 24, raylib.colors.Black);
            raylib.drawText(try std.fmt.bufPrintZ(&score_buff, "Score: {d}", .{state.score}), 6, 30, 24, raylib.colors.Black);
        }

        raylib.beginDrawing();
        defer raylib.endDrawing();
        raylib.clearBackground(raylib.colors.RayWhite);
        raylib.drawTextureRec(background.texture, .{
            .x = 0,
            .y = 0,
            .width = screen.width,
            .height = -screen.height,
        }, .{ 0, 0 }, raylib.colors.RayWhite);
        if (state.game_over) {
            raylib.drawText("GAME OVER", (screen.width / 2) - (24 * 4), (screen.height / 2) - 12, 24, Red);
        }
    }
}
