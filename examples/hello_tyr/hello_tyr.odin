package hello_tyr

import "../.."
import rl "vendor:raylib"

main :: proc() {
	app := tyr.app_new()
	app.start_fullscreen = false
	defer tyr.app_run(&app)
	app.start = proc(app: ^tyr.app) {
		rl.SetWindowTitle("Hello, Tyr!")
		// runs once
	}
	app.update = proc(app: ^tyr.app, dt: f32) {
		// runs every frame
	}
	app.fixed_update = proc(app: ^tyr.app, dt: f32) {
		// runs at a fixed time step
	}
}
