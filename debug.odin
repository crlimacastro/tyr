package tyr

import im "odin-imgui"
import rl "vendor:raylib"

debug_quit_on_escape_system :: proc(#by_ptr step: update_step) {
	when !ODIN_DEBUG {
		return
	}
	input_quit_on_escape_system(step)
}

debug_should_render_fps := false

debug_render_fps_system :: proc(#by_ptr step: rendering_step) {
	when !ODIN_DEBUG {
		return
	}
	input, ok := resources_get(step.resources, input)
	if !ok {return}
	if input_is_key_pressed(input, .grave) {
		debug_should_render_fps = !debug_should_render_fps
	}
	if !debug_should_render_fps {return}
	rl.DrawFPS(10, 10)
}

debug_show_imgui_demo_window_system :: proc(#by_ptr step: editor_update_step) {
	when !ODIN_DEBUG {
		return
	}
	im.ShowDemoWindow()
}
