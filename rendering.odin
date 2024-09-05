package tyr

import rl "vendor:raylib"

color :: distinct [4]u8

black :: color{0, 0, 0, 255}
cornflower_blue :: color{100, 149, 237, 255}

clear_color :: distinct color

render_step :: struct {
	resources: ^resources,
	scheduler: ^scheduler,
}

rendering_plugin :: proc(app: ^app) {
	resources_set(&app.resources, clear_color, clear_color(black))
	app_add_systems(app, update_step, quit_on_window_should_close, update_rendering)
	app_add_systems(app, deinit_step, deinit_rendering)

	rl.SetTraceLogLevel(.WARNING)
	config_flags: rl.ConfigFlags = {.WINDOW_RESIZABLE}
	// 	config_flags |= rl.ConfigFlags{.FULLSCREEN_MODE}
	rl.SetConfigFlags(config_flags)
	rl.InitWindow(1920, 1080, "")
	rl.SetExitKey(.KEY_NULL)
}

quit_on_window_should_close :: proc(#by_ptr step: update_step) {
	if !rl.WindowShouldClose() {
		return
	}
	scheduler_dispatch(
		step.scheduler,
		app_quit,
		app_quit{resources = step.resources, scheduler = step.scheduler},
	)
}

update_rendering :: proc(#by_ptr step: update_step) {
	rl.BeginDrawing()

	clear_col := black
	maybe_clear_color, ok := resources_get(step.resources, clear_color)
	if ok {
		clear_col = color(maybe_clear_color^)
	}
	rl.ClearBackground(rl.Color(clear_col))

	scheduler_dispatch(
		step.scheduler,
		render_step,
		render_step{resources = step.resources, scheduler = step.scheduler},
	)

	rl.EndDrawing()
}

deinit_rendering :: proc(#by_ptr step: deinit_step) {
	rl.CloseWindow()
}
