package tyr

import rl "vendor:raylib"

app :: struct {
	auto_delete:                    bool,
	is_running:                     bool,
	clear_color:                    rl.Color,
	start_fullscreen:               bool,
	start:                          proc(app: ^app),
	toggle_fullscreen_on_alt_enter: bool,
	update:                         proc(app: ^app, dt: f32),
	fixed_time_step:                f32,
	fixed_update:                   proc(app: ^app, dt: f32),
}

app_new :: proc() -> app {
	return app {
		auto_delete = true,
		clear_color = rl.BLACK,
		start_fullscreen = true,
		start = proc(app: ^app) {},
		toggle_fullscreen_on_alt_enter = true,
		update = proc(app: ^app, dt: f32) {},
		fixed_time_step = 1.0 / 60.0,
		fixed_update = proc(app: ^app, dt: f32) {},
	}
}

app_delete :: proc(app: ^app) {
}

@(private = "file")
fixed_time_accumulator: f32

app_run :: proc(app: ^app) {
	rl.SetTraceLogLevel(.WARNING)
	config_flags: rl.ConfigFlags = {.WINDOW_RESIZABLE}
	if app.start_fullscreen {
		config_flags |= rl.ConfigFlags{.FULLSCREEN_MODE}
	}
	rl.SetConfigFlags(config_flags)
	rl.InitWindow(1920, 1080, "")
	rl.SetExitKey(.KEY_NULL)

	app.is_running = true
	app.start(app)

	for app.is_running {
		free_all(context.temp_allocator)

		if rl.WindowShouldClose() {
			app.is_running = false
			break
		}

		if app.toggle_fullscreen_on_alt_enter {
			if rl.IsKeyDown(.LEFT_ALT) && rl.IsKeyPressed(.ENTER) {
				rl.ToggleFullscreen()
			}
		}

		rl.BeginDrawing()

		rl.ClearBackground(app.clear_color)

		dt := rl.GetFrameTime()

		fixed_time_accumulator += dt
		for fixed_time_accumulator >= app.fixed_time_step {
			app.fixed_update(app, app.fixed_time_step)
			fixed_time_accumulator -= app.fixed_time_step
		}

		app.update(app, dt)

		rl.EndDrawing()
	}
	rl.CloseWindow()

	if (app.auto_delete) {
		app_delete(app)
	}
}
