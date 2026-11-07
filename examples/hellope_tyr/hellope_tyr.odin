package hellope_tyr

import tyr "../.."
import rl "vendor:raylib"

main :: proc() {
	a := tyr.app_init()
	defer tyr.app_deinit(&a)
	tyr.app_add_plugins(&a, tyr.default_plugins_plugin, tyr.editor_plugin)
	// app_add_systems(&a, update_step, debug_quit_on_escape_system)
	tyr.app_add_systems(&a, tyr.rendering_step, tyr.debug_render_fps_system)
	tyr.app_add_systems(&a, tyr.editor_update_step, tyr.debug_show_imgui_demo_window_system)
	tyr.app_add_systems(&a, tyr.start_step, proc(#by_ptr step: tyr.start_step) {
		if window, ok := tyr.resources_get(step.resources, tyr.window); ok {
			tyr.window_set_title(window, "Hellope, Tyr!")
		}
		main_camera := tyr.resources_get_or_make(step.resources, tyr.main_camera)


		e := tyr.ecs_create_entity(step.ecs_ctx)
		tyr.ecs_set_component(step.ecs_ctx, e, tyr.name("sprite"))
		tyr.ecs_set_component(step.ecs_ctx, e, tyr.transform2{translation = {500, 200}, scale = {1, 1}})

		if renderer, ok := tyr.resources_get(step.resources, tyr.renderer); ok {
			texture := tyr.renderer_load_texture(renderer, "link.png")
			tyr.ecs_set_component(step.ecs_ctx, e, tyr.sprite_new(texture))
		}

		tyr.ecs_create_entity(step.ecs_ctx)

		e2 := tyr.ecs_create_entity(step.ecs_ctx)
		tyr.ecs_set_component(step.ecs_ctx, e2, tyr.name("cube"))
		tyr.ecs_set_component(
			step.ecs_ctx,
			e2,
			tyr.transform {
				translation = {0, 0, 10},
				scale = {1, 1, 1},
				rotation = quaternion(x = 0, y = 0, z = 0, w = 1),
			},
		)
		tyr.ecs_set_component(step.ecs_ctx, e2, rl.GenMeshCube(1, 1, 1))

		e3 := tyr.ecs_create_entity(step.ecs_ctx)
		tyr.ecs_set_component(step.ecs_ctx, e3, tyr.name("camera"))
		tyr.ecs_set_component(
			step.ecs_ctx,
			e3,
			tyr.transform {
				translation = {0, 0, 0},
				scale = {1, 1, 1},
				rotation = quaternion(x = 0, y = 0, z = 0, w = 1),
			},
		)
		tyr.ecs_set_component(step.ecs_ctx, e3, tyr.camera{fovy = 45, projection = .PERSPECTIVE})
		main_cam := tyr.resources_get_or_make(step.resources, tyr.main_camera3d)
		main_cam.entity = e3
	})
	tyr.app_run(&a)
}
