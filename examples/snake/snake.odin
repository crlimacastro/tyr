package snake

import "../.."
import "core:c"
import "core:math/rand"
import rl "vendor:raylib"

cell_count :: 20
starting_direction :: vec2i {
	x = 1,
	y = 0,
}
primary_color :: rl.Color{12, 124, 89, 255}
secondary_color :: rl.Color{214, 73, 51, 255}

vec2i :: struct {
	x: int,
	y: int,
}

cell :: struct {
	position: vec2i,
}

apple :: struct {
	cell:  cell,
	eaten: bool,
}

snake_cell :: struct {
	cell: cell,
	new:  bool,
}

snake :: struct {
	cells:     [dynamic]snake_cell,
	direction: vec2i,
}
player: snake
apples: [dynamic]apple

start_seconds_per_step :: 1.0
seconds_per_step: f32
delta_seconds_per_step: f32 = 0.001
min_seconds_per_step :: 0.01
step_accumulator: f32
seconds_per_apple: f32 = 4.0
apples_accumulator: f32
paused: bool = true

main :: proc() {
	app := tyr.app_new()
	app.start_fullscreen = false
	defer tyr.app_run(&app)
	app.start = proc(app: ^tyr.app) {
		rl.SetWindowTitle("Snake")
		reset()
	}
	app.update = proc(app: ^tyr.app, dt: f32) {
		defer tyr.debug_draw_fps(10, 10)

		if !paused {
			step_accumulator += dt
			for step_accumulator >= seconds_per_step {
				step(app)
				step_accumulator -= seconds_per_step
			}
			apples_accumulator += dt
			for apples_accumulator >= seconds_per_apple {
				spawn_apple()
				apples_accumulator -= seconds_per_apple
			}
		}

		tyr.debug_quit_on_escape(app)

		poll_player_input()

		for &apple in apples {
			draw_cell(&apple.cell, secondary_color)
		}
		draw_snake(&player)
		draw_grid()
	}
}

reset :: proc() {
	player.direction = starting_direction
	clear(&player.cells)
	append(
		&player.cells,
		snake_cell{cell = cell{position = vec2i{x = cell_count / 2, y = cell_count / 2}}},
	)
	step_accumulator = 0.0
	apples_accumulator = 0.0
	seconds_per_step = start_seconds_per_step
	clear(&apples)
	paused = true
}

step :: proc(app: ^tyr.app) {
	seconds_per_step -= delta_seconds_per_step
	seconds_per_step = max(seconds_per_step, min_seconds_per_step)
	move_snake(&player)
	detect_collisions()
}

poll_player_input :: proc() {
	key := rl.GetKeyPressed()

	if (key != .KEY_NULL) {
		paused = false
	}

	if len(player.cells) > 1 {
		head := snake_head_cell(&player)
		second_cell := &player.cells[1].cell
		if key == .W || key == .UP {
			if head.position.y - 1 == second_cell.position.y {
				return
			}
		}
		if key == .S || key == .DOWN {
			if head.position.y + 1 == second_cell.position.y {
				return
			}
		}
		if key == .A || key == .LEFT {
			if head.position.x - 1 == second_cell.position.x {
				return
			}
		}
		if key == .D || key == .RIGHT {
			if head.position.x + 1 == second_cell.position.x {
				return
			}
		}
	}
	#partial switch key {
	case .W, .UP:
		player.direction = {0, -1}
	case .S, .DOWN:
		player.direction = {0, 1}
	case .A, .LEFT:
		player.direction = {-1, 0}
	case .D, .RIGHT:
		player.direction = {1, 0}
	}
}

detect_collisions :: proc() {
	head := snake_head_cell(&player)
	head_pos := &head.position
	{
		if head_pos.x < 0 ||
		   head_pos.x >= cell_count ||
		   head_pos.y < 0 ||
		   head_pos.y >= cell_count {
			reset()
		}
	}
	for &apple, i in apples {
		apple_pos := &apple.cell.position
		if apple_pos.x == head_pos.x && apple_pos.y == head_pos.y {
			eat_apple(i)
		}
	}
	for &snake_cell, i in player.cells[1:] {
		if snake_cell.new {
			continue
		}
		cell_pos := &snake_cell.cell.position
		if cell_pos.x == head_pos.x && cell_pos.y == head_pos.y {
			reset()
		}
	}
}

eat_apple :: proc(i: int) {
	last_cell := &player.cells[len(player.cells) - 1].cell
	append(
		&player.cells,
		snake_cell {
			cell = cell{position = vec2i{x = last_cell.position.x, y = last_cell.position.y}},
			new = true,
		},
	)
	ordered_remove(&apples, i)
}

move_snake :: proc(snake: ^snake) {
	#reverse for &cell, i in snake.cells {
		if cell.new {
			cell.new = false
			continue
		}
		cell_pos := &cell.cell.position
		if i == 0 {
			cell_pos.x += snake.direction.x
			cell_pos.y += snake.direction.y
		} else {
			previous := &snake.cells[i - 1].cell
			cell_pos.x = previous.position.x
			cell_pos.y = previous.position.y
		}
	}
}

spawn_apple :: proc() {
	if all_cells_occupied() {
		return
	}

	pos := rand_vec2i_in_grid()

	append(&apples, apple{cell = cell{position = vec2i{pos.x, pos.y}}})
}

rand_vec2i_in_grid :: proc() -> vec2i {
	blocked := true
	pos := vec2i{}
	for blocked {
		pos = vec2i {
			x = rand.int_max(cell_count),
			y = rand.int_max(cell_count),
		}
		for &apple in apples {
			if apple.cell.position.x == pos.x && apple.cell.position.y == pos.y {
				continue
			}
		}
		for &snake_cell in player.cells {
			if snake_cell.cell.position.x == pos.x && snake_cell.cell.position.y == pos.y {
				continue
			}
		}
		blocked = false
	}

	return pos
}

draw_snake :: proc(snake: ^snake) {
	#reverse for &snake_cell, i in snake.cells {
		color := primary_color
		if i != 0 {
			color.rgb /= 2
		}
		draw_cell(&snake_cell.cell, color)
	}
}

draw_cell :: proc(cell: ^cell, color: rl.Color = primary_color) {
	rect := rl.Rectangle {
		x      = x_pad() + f32(cell.position.x) * cell_size(),
		y      = y_pad() + f32(cell.position.y) * cell_size(),
		width  = cell_size(),
		height = cell_size(),
	}
	rl.DrawRectangleRec(rect, color)
}

draw_grid :: proc() {
	for i in 0 ..< cell_count {
		for j in 0 ..< cell_count {
			color := primary_color
			color.a = 255 / 4
			rl.DrawRectangleLines(
				c.int(x_pad() + f32(i) * cell_size()),
				c.int(y_pad() + f32(j) * cell_size()),
				c.int(cell_size()),
				c.int(cell_size()),
				color,
			)
		}
	}
}

snake_head_cell :: proc(snake: ^snake) -> cell {
	return snake.cells[0].cell
}

cell_size :: proc() -> f32 {
	return min_dim() / cell_count
}

min_dim :: proc() -> f32 {
	return f32(min(rl.GetScreenWidth(), rl.GetScreenHeight()))
}

max_dim :: proc() -> f32 {
	return f32(max(rl.GetScreenWidth(), rl.GetScreenHeight()))
}

gutter :: proc() -> f32 {
	return (max_dim() - cell_count * cell_size()) / 2.0
}

x_pad :: proc() -> f32 {
	if rl.GetScreenWidth() > rl.GetScreenHeight() {
		return gutter()
	}
	return 0
}

y_pad :: proc() -> f32 {
	if rl.GetScreenHeight() > rl.GetScreenWidth() {
		return gutter()
	}
	return 0
}

all_cells_occupied :: proc() -> bool {
	full_cell_count :: cell_count * cell_count
	return full_cell_count <= len(player.cells) + len(apples)
}
