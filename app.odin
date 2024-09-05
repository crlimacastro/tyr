package tyr

import rl "vendor:raylib"

plugin :: proc(app: ^app)

init_step :: struct {
	resources: ^resources,
	scheduler: ^scheduler,
}

start_step :: struct {
	resources: ^resources,
	scheduler: ^scheduler,
}

update_step :: struct {
	resources: ^resources,
	scheduler: ^scheduler,
}

fixed_update_step :: struct {
	resources: ^resources,
	scheduler: ^scheduler,
}

stop_step :: struct {
	resources: ^resources,
	scheduler: ^scheduler,
}

deinit_step :: struct {
	resources: ^resources,
	scheduler: ^scheduler,
}

app_quit :: struct {
	resources: ^resources,
	scheduler: ^scheduler,
}

app :: struct {
	is_running:             bool,
	fixed_time_step:        f32,
	fixed_time_accumulator: f32,
	plugins:                map[plugin]bool,
	resources:              resources,
	scheduler:              scheduler,
}

app_new :: proc() -> app {
	return app{fixed_time_step = 1.0 / 60.0}
}

app_delete :: proc(app: ^app) {
	delete(app.plugins)
	delete(app.resources)
	delete(app.scheduler)
}


app_run :: proc(a: ^app) {
	a.is_running = true
	resources_set(&a.resources, ^app, a)
	app_add_systems(a, app_quit, proc(#by_ptr e: app_quit) {
		maybe_app, ok := resources_get(e.resources, ^app)
		if ok {
			maybe_app^.is_running = false
		}
	})
	scheduler_dispatch(
		&a.scheduler,
		init_step,
		init_step{resources = &a.resources, scheduler = &a.scheduler},
	)
	scheduler_dispatch(
		&a.scheduler,
		start_step,
		start_step{resources = &a.resources, scheduler = &a.scheduler},
	)
	for a.is_running {
		free_all(context.temp_allocator)

		scheduler_dispatch(
			&a.scheduler,
			update_step,
			update_step{resources = &a.resources, scheduler = &a.scheduler},
		)

		dt := rl.GetFrameTime()
		a.fixed_time_accumulator += dt
		for a.fixed_time_accumulator >= a.fixed_time_step {
			scheduler_dispatch(
				&a.scheduler,
				fixed_update_step,
				fixed_update_step{resources = &a.resources, scheduler = &a.scheduler},
			)
			a.fixed_time_accumulator -= a.fixed_time_step
		}
	}
	scheduler_dispatch(
		&a.scheduler,
		stop_step,
		stop_step{resources = &a.resources, scheduler = &a.scheduler},
	)
	scheduler_dispatch(
		&a.scheduler,
		deinit_step,
		deinit_step{resources = &a.resources, scheduler = &a.scheduler},
	)
}

app_add_plugins :: proc(app: ^app, plugins: ..plugin) {
	for plugin in plugins {
		if app.plugins[plugin] {
			continue
		}
		app.plugins[plugin] = true
		plugin(app)
	}
}

app_add_systems :: proc(app: ^app, $t_event: typeid, systems: ..proc(#by_ptr arg: t_event)) {
	scheduler_add_systems(&app.scheduler, t_event, ..systems)
}
