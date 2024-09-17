package tyr

import rl "vendor:raylib"

input_plugin :: proc(app: ^app) {
	app_add_systems(app, update_step, input_toggle_fullscreen_on_alt_enter_system)
}

input_toggle_fullscreen_on_alt_enter_system :: proc(#by_ptr step: update_step) {
	if rl.IsKeyDown(.LEFT_ALT) && rl.IsKeyPressed(.ENTER) {
		rl.ToggleFullscreen()
	}
}

input_quit_on_escape_system :: proc(#by_ptr step: update_step) {
	if rl.IsKeyPressed(.ESCAPE) {
		scheduler_dispatch(step.scheduler, app_quit, app_quit{})
	}
}

input_debug_quit_on_escape_system :: proc(#by_ptr step: update_step) {
	when ODIN_DEBUG {
		return
	}
	if rl.IsKeyPressed(.ESCAPE) {
		scheduler_dispatch(step.scheduler, app_quit, app_quit{})
	}
}
