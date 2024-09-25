package hellope_tyr

import tyr "../.."
import im "../../odin-imgui"

main :: proc() {
	using tyr
	a := app_init()
	defer app_deinit(&a)
	defer app_run(&a)
	app_add_plugins(&a, default_plugins_plugin, editor_plugin)
	app_add_systems(&a, update_step, debug_quit_on_escape_system)
	app_add_systems(&a, rendering_step, debug_render_fps_system)
	app_add_systems(&a, start_step, proc(#by_ptr step: start_step) {
		{
			window, ok := resources_get(step.resources, window)
			if ok {
				window_set_title(window, "Hellope, Tyr!")
			}
		}

		e := ecs_create_entity(step.ecs_ctx)
		ecs_set_component(step.ecs_ctx, e, name("test entity"))
		ecs_set_component(step.ecs_ctx, e, transform2{translation={500, 200}, scale={1, 1}})
		{
			renderer, ok := resources_get(step.resources, renderer)
			if ok {
				texture := renderer_load_texture(renderer, "link.png")

				ecs_set_component(
					step.ecs_ctx,
					e,
					sprite_new(texture)
					
				)
			}
		}
		ecs_create_entity(step.ecs_ctx)
	})
	// app_add_systems(&a, editor_step, proc(#by_ptr step: editor_step) {
	// 	im.ShowDemoWindow()
	// })
}
