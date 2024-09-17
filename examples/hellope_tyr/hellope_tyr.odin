package hellope_tyr

import tyr "../.."
import ecs "../../odin-ecs"
import rl "vendor:raylib"

main :: proc() {
	using tyr
	a := app_new()
	defer app_delete(&a)
	defer app_run(&a)
	app_add_plugins(&a, default_plugins_plugin, editor_plugin)
	when ODIN_DEBUG {
		app_add_systems(&a, update_step, input_quit_on_escape_system)
	}
	app_add_systems(
		&a,
		start_step,
		proc(#by_ptr step: start_step) {
			// called once at the start of the application
			rl.SetWindowTitle("Hellope, Tyr!")
			e := ecs.create_entity(step.ecs_ctx)
			ecs.add_component(step.ecs_ctx, e, name("test entity"))
			ecs.add_component(step.ecs_ctx, e, rl.Transform{translation={500, 200, 0}, scale={1, 1, 1}})
			ecs.add_component(step.ecs_ctx, e, rl.Rectangle{x=0, y=0, width=100, height=100})
			ecs.add_component(step.ecs_ctx, e, tyr.cornflower_blue)
			ecs.create_entity(step.ecs_ctx)
		},
	)
	app_add_systems(&a, update_step, update)
	app_add_systems(
		&a,
		fixed_update_step,
		proc(#by_ptr step: fixed_update_step) {
			// called at a fixed time interval (60fps by default
		},
	)
	app_add_systems(
		&a,
		rendering_step,
		proc(#by_ptr step: rendering_step) {
			// called between begin and end render calls
		},
	)
	app_add_systems(
		&a,
		stop_step,
		proc(#by_ptr step: stop_step) {
			// called once after the application quits
		},
	)
}

update :: proc(#by_ptr step: tyr.update_step) {
	// called every frame
}
