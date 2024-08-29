package wasd

import "../.."
import "core:c"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

player_rect: rl.Rectangle
player_speed :: 10.0

debug_text_size :: 20
debug_text_spacing :: 10
debug_text_x :: 10
next_debug_text_y: int

main :: proc() {
	app := tyr.app_new()
	app.start_fullscreen = false
	defer tyr.app_run(&app)
	app.start = proc(app: ^tyr.app) {
		rl.SetWindowTitle("WASD")
		player_rect = rl.Rectangle {
			f32(rl.GetScreenWidth() / 2),
			f32(rl.GetScreenHeight() / 2),
			40,
			40,
		}
	}
	app.update = proc(app: ^tyr.app, dt: f32) {
		next_debug_text_y = debug_text_spacing

		tyr.debug_quit_on_escape(app)
		defer 
		{
			tyr.debug_draw_fps(debug_text_x, next_debug_text_y)
			next_debug_text_y += debug_text_size + debug_text_spacing
		}

		input := get_player_input()

		b: strings.Builder
		strings.builder_init(&b)
		strings.write_string(&b, to_text(input.move))
		rl.DrawText(
			strings.to_cstring(&b),
			debug_text_x,
			c.int(next_debug_text_y),
			debug_text_size,
			rl.WHITE,
		)
		next_debug_text_y += debug_text_size + debug_text_spacing

		rl.DrawRectangleRec(player_rect, rl.RAYWHITE)
	}
	app.fixed_update = proc(app: ^tyr.app, dt: f32) {
		input := get_player_input()
		player_rect.x += input.move.x * player_speed
		player_rect.y += input.move.y * player_speed
	}
}

player_input :: struct {
	move: rl.Vector2,
}

get_player_input :: proc() -> player_input {
	input: player_input
	if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
		input.move.y += -1
	}
	if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
		input.move.y += 1
	}
	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
		input.move.x += -1
	}
	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
		input.move.x += 1
	}
	if input.move != rl.Vector2(0) {
		input.move = rl.Vector2Normalize(input.move)
	}
	return input
}

to_text :: proc(value: rl.Vector2) -> string {
	b: strings.Builder
	strings.builder_init(&b)
	fmt.sbprintf(&b, "[%f, %f]", value.x, value.y)
	return strings.to_string(b)
}
