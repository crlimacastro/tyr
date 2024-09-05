package hellope_tyr

import tyr "../.."
import rl "vendor:raylib"

main :: proc() {
	using tyr
	a := app_new()
	defer app_delete(&a)
	defer app_run(&a)
	app_add_plugins(&a, default_plugins)
	when ODIN_DEBUG {
		app_add_systems(&a, update_step, quit_on_escape)
	}
	app_add_systems(&a, start_step, proc(#by_ptr step: start_step) {
		// called once at the start of the application
		rl.SetWindowTitle("Hellope, Tyr!")
	})
	app_add_systems(&a, update_step, update)
	app_add_systems(&a, fixed_update_step, proc(#by_ptr step: fixed_update_step) {
		// called at a fixed time interval (60fps by default
	})
	app_add_systems(&a, render_step, proc(#by_ptr step: render_step) {
		// called between begin and end render calls
	})
	app_add_systems(&a, stop_step, proc(#by_ptr step: stop_step) {
		// called once after the application quits
	})
}

update :: proc(#by_ptr step: tyr.update_step) {
	// called every frame
}
