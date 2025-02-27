package hellope_tyr

import tyr "../.."
import rl "vendor:raylib"

main :: proc() {
	using tyr
	a := app_init()
	defer app_deinit(&a)
	app_add_plugins(&a, default_plugins_plugin, editor_plugin)
	// app_add_systems(&a, update_step, debug_quit_on_escape_system)
	app_add_systems(&a, rendering_step, debug_render_fps_system)
	app_add_systems(&a, editor_update_step, debug_show_imgui_demo_window_system)
	app_add_systems(&a, start_step, proc(#by_ptr step: start_step) {
		if window, ok := resources_get(step.resources, window); ok {
			window_set_title(window, "Hellope, Tyr!")
		}
		main_camera := resources_get_or_make(step.resources, main_camera)


		e := ecs_create_entity(step.ecs_ctx)
		ecs_set_component(step.ecs_ctx, e, name("sprite"))
		ecs_set_component(step.ecs_ctx, e, transform2{translation = {500, 200}, scale = {1, 1}})

		if renderer, ok := resources_get(step.resources, renderer); ok {
			texture := renderer_load_texture(renderer, "link.png")
			ecs_set_component(step.ecs_ctx, e, sprite_new(texture))
		}

		ecs_create_entity(step.ecs_ctx)

		e2 := ecs_create_entity(step.ecs_ctx)
		ecs_set_component(step.ecs_ctx, e2, name("cube"))
		ecs_set_component(
			step.ecs_ctx,
			e2,
			transform {
				translation = {0, 0, 10},
				scale = {1, 1, 1},
				rotation = quaternion(x = 0, y = 0, z = 0, w = 1),
			},
		)
		ecs_set_component(step.ecs_ctx, e2, tyr.rl_mesh_to_rendering_mesh(rl.GenMeshCube(1, 1, 1)))

		e3 := ecs_create_entity(step.ecs_ctx)
		ecs_set_component(step.ecs_ctx, e3, name("camera"))
		ecs_set_component(
			step.ecs_ctx,
			e3,
			transform {
				translation = {0, 0, 0},
				scale = {1, 1, 1},
				rotation = quaternion(x = 0, y = 0, z = 0, w = 1),
			},
		)
		ecs_set_component(
			step.ecs_ctx,
			e3,
			tyr.camera{fovy = 45, projection = tyr.camera_projection.perspective},
		)
		main_cam := resources_get_or_make(step.resources, main_camera3d)
		main_cam.entity = e3
	})
	app_run(&a)
}
