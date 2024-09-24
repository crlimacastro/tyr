package tyr

import rl "vendor:raylib"

plugin :: proc(app: ^app)

// check app_steps.odin for examples of available steps
app_step :: struct {
	resources: ^resources,
	scheduler: ^scheduler,
	ecs_ctx:   ^ecs_context,
}

app_quit :: struct {
	using step: app_step,
}

app :: struct {
	is_running:             bool,
	fixed_time_step:        fp,
	fixed_time_accumulator: fp,
	plugins:                map[plugin]bool,
	resources:              resources,
	scheduler:              scheduler,
	ecs_ctx:                ecs_context,
}

app_init :: proc() -> app {
	return app{fixed_time_step = 1.0 / 60.0, ecs_ctx = ecs_init()}
}

app_deinit :: proc(a: ^app) {
	delete(a.plugins)
	delete(a.resources)
	delete(a.scheduler)
	ecs_deinit(&a.ecs_ctx)
}


app_run :: proc(a: ^app) {
	a.is_running = true
	resources_set(&a.resources, a)
	app_add_systems(a, app_quit, proc(#by_ptr e: app_quit) {
		maybe_app, ok := resources_get(e.resources, ^app)
		if ok {
			maybe_app^.is_running = false
		}
	})
	scheduler_dispatch(
		&a.scheduler,
		init_step,
		init_step{resources = &a.resources, scheduler = &a.scheduler, ecs_ctx = &a.ecs_ctx},
	)
	scheduler_dispatch(
		&a.scheduler,
		start_step,
		start_step{resources = &a.resources, scheduler = &a.scheduler, ecs_ctx = &a.ecs_ctx},
	)
	for a.is_running {
		free_all(context.temp_allocator)

		scheduler_dispatch(
			&a.scheduler,
			update_step,
			update_step{resources = &a.resources, scheduler = &a.scheduler, ecs_ctx = &a.ecs_ctx},
		)

		dt := rl.GetFrameTime()
		a.fixed_time_accumulator += dt
		for a.fixed_time_accumulator >= a.fixed_time_step {
			scheduler_dispatch(
				&a.scheduler,
				fixed_update_step,
				fixed_update_step {
					resources = &a.resources,
					scheduler = &a.scheduler,
					ecs_ctx = &a.ecs_ctx,
				},
			)
			a.fixed_time_accumulator -= a.fixed_time_step
		}
	}
	scheduler_dispatch(
		&a.scheduler,
		stop_step,
		stop_step{resources = &a.resources, scheduler = &a.scheduler, ecs_ctx = &a.ecs_ctx},
	)
	scheduler_dispatch(
		&a.scheduler,
		deinit_step,
		deinit_step{resources = &a.resources, scheduler = &a.scheduler, ecs_ctx = &a.ecs_ctx},
	)
}

app_add_plugins :: proc(a: ^app, plugins: ..plugin) {
	for plugin in plugins {
		if a.plugins[plugin] {
			continue
		}
		a.plugins[plugin] = true
		plugin(a)
	}
}

app_add_systems :: proc(a: ^app, $t_event: typeid, systems: ..proc(#by_ptr arg: t_event)) {
	scheduler_add_systems(&a.scheduler, t_event, ..systems)
}

app_set_resource :: proc(a: ^app, resource: $resource_t) {
	resources_set(&a.resources, resource)
}
