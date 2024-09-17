package tyr

import ecs "odin-ecs"
import rl "vendor:raylib"

color :: distinct [4]u8

black :: color{0, 0, 0, 255}
cornflower_blue :: color{100, 149, 237, 255}

clear_color :: distinct color

rendering_step :: struct {
	using step: app_step,
}

rendering_plugin :: proc(app: ^app) {
	resources_set(&app.resources, clear_color, clear_color(black))
	app_add_systems(
		app,
		update_step,
		rendering_quit_on_window_should_close_system,
		rendering_update_system,
	)
	app_add_systems(app, rendering_step, render_rectangles)
	app_add_systems(app, deinit_step, rendering_deinit_system)

	rl.SetTraceLogLevel(.WARNING)
	config_flags: rl.ConfigFlags = {.WINDOW_RESIZABLE}
	// 	config_flags |= rl.ConfigFlags{.FULLSCREEN_MODE}
	rl.SetConfigFlags(config_flags)
	rl.InitWindow(1920, 1080, "")
	rl.SetExitKey(.KEY_NULL)
}

rendering_quit_on_window_should_close_system :: proc(#by_ptr step: update_step) {
	if !rl.WindowShouldClose() {
		return
	}
	scheduler_dispatch(
		step.scheduler,
		app_quit,
		app_quit{resources = step.resources, scheduler = step.scheduler},
	)
}

rendering_update_system :: proc(#by_ptr step: update_step) {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	clear_col := black
	maybe_clear_color, ok := resources_get(step.resources, clear_color)
	if ok {
		clear_col = color(maybe_clear_color^)
	}
	rl.ClearBackground(rl.Color(clear_col))

	scheduler_dispatch(
		step.scheduler,
		rendering_step,
		rendering_step {
			resources = step.resources,
			scheduler = step.scheduler,
			ecs_ctx = step.ecs_ctx,
		},
	)
}

render_rectangles :: proc(#by_ptr step: rendering_step) {
	rects, err := ecs.get_component_list(step.ecs_ctx, rl.Rectangle)
	if err != .NO_ERROR {return}
	for rect, i in &rects {
		e := ecs.Entity(i)
		translation := rl.Vector2{}
		rotation: f32 = 0
		scale := rl.Vector2{1, 1}
		col := rl.WHITE
		if transform, err := ecs.get_component(step.ecs_ctx, e, rl.Transform); err == .NO_ERROR {
			translation = transform.translation.xy
			euler := rl.QuaternionToEuler(transform.rotation) * rl.RAD2DEG
			rotation = euler.z
			scale = transform.scale.xy
		}
		if c, err := ecs.get_component(step.ecs_ctx, e, color); err == .NO_ERROR {
			col = rl.Color(c^)
		}
		width := rect.width * scale.x
		height := rect.height * scale.y
		rl.DrawRectanglePro(
			rl.Rectangle{x = translation.x, y = translation.y, width = width, height = height},
			rl.Vector2{width / 2, height / 2},
			rotation,
			col,
		)
	}
}

rendering_deinit_system :: proc(#by_ptr step: deinit_step) {
	rl.CloseWindow()
}
