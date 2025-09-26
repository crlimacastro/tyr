package tyr

import "core:strings"
import imrl "imgui_raylib_impl"
import im "odin-imgui"

ui_selectable_flag :: im.SelectableFlag
ui_selectable_flags :: im.SelectableFlags
ui_color_edit_flag :: im.ColorEditFlag
ui_color_edit_flags :: im.ColorEditFlags
ui_window_flag :: im.WindowFlag
ui_window_flags :: im.WindowFlags
ui_slider_flag :: im.SliderFlag
ui_slider_flags :: im.SliderFlags
ui_dock_node_flag :: im.DockNodeFlag
ui_dock_node_flags :: im.DockNodeFlags
ui_input_text_flag :: im.InputTextFlag
ui_input_text_flags :: im.InputTextFlags

cstring_buffers_length :: 1024

imgui_main_menu_bar_ui :: proc() -> main_menu_bar_ui {
	return {data = {}, begin_menu = proc(data: rawptr, label: string) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			return im.BeginMenu(label_cstr)
		}, end_menu = proc(data: rawptr) {
			im.EndMenu()
		}, menu_item = proc(data: rawptr, label: string) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			return im.MenuItem(label_cstr)
		}}
}

imgui_ui :: proc() -> ui {
	return {
		data = {},
		begin_window = proc(
			data: rawptr,
			name: string,
			open: ^bool,
			flags: ui_window_flags,
		) -> bool {
			name_cstr := strings.clone_to_cstring(name, context.temp_allocator)
			return im.Begin(name_cstr, open, flags)
		},
		end_window = proc(data: rawptr) {
			im.End()
		},
		button = proc(data: rawptr, label: string) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			return im.Button(label_cstr)
		},
		selectable = proc(
			data: rawptr,
			label: string,
			selected: bool = false,
			flags: ui_selectable_flags = {},
			size: vec2,
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			return im.Selectable(label_cstr, selected, flags, size)
		},
		tree_node = proc(data: rawptr, label: string) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			return im.TreeNode(label_cstr)
		},
		tree_pop = proc(data: rawptr) {
			im.TreePop()
		},
		color_edit_4 = proc(
			data: rawptr,
			label: string,
			col: ^[4]fp,
			flags: ui_color_edit_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			return im.ColorEdit4(label_cstr, col, flags)
		},
		drag_int = proc(
			data: rawptr,
			label: string,
			v: ^i32,
			v_speed: f32 = 1,
			v_min: i32 = 0,
			v_max: i32 = 0,
			format: string = "%d",
			flags: ui_slider_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			format_cstr := strings.clone_to_cstring(format, context.temp_allocator)
			return im.DragInt(label_cstr, v, v_speed, v_min, v_max, format_cstr, flags)
		},
		drag_int2 = proc(
			data: rawptr,
			label: string,
			v: ^[2]i32,
			v_speed: f32 = 1,
			v_min: i32 = 0,
			v_max: i32 = 0,
			format: string = "%d",
			flags: ui_slider_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			format_cstr := strings.clone_to_cstring(format, context.temp_allocator)
			return im.DragInt2(label_cstr, v, v_speed, v_min, v_max, format_cstr, flags)
		},
		drag_int3 = proc(
			data: rawptr,
			label: string,
			v: ^[3]i32,
			v_speed: f32 = 1,
			v_min: i32 = 0,
			v_max: i32 = 0,
			format: string = "%d",
			flags: ui_slider_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			format_cstr := strings.clone_to_cstring(format, context.temp_allocator)
			return im.DragInt3(label_cstr, v, v_speed, v_min, v_max, format_cstr, flags)
		},
		drag_uint = proc(
			data: rawptr,
			label: string,
			v: ^u32,
			v_speed: f32 = 1,
			v_min: u32 = 0,
			v_max: u32 = 0,
			format: string = "%u",
			flags: ui_slider_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			format_cstr := strings.clone_to_cstring(format, context.temp_allocator)
			v_i32 := i32(v^)
			ret := im.DragInt(
				label_cstr,
				&v_i32,
				v_speed,
				i32(v_min),
				i32(v_max),
				format_cstr,
				flags,
			)
			v^ = u32(v_i32)
			return ret
		},
		drag_uint2 = proc(
			data: rawptr,
			label: string,
			v: ^[2]u32,
			v_speed: f32 = 1,
			v_min: u32 = 0,
			v_max: u32 = 0,
			format: string = "%u",
			flags: ui_slider_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			format_cstr := strings.clone_to_cstring(format, context.temp_allocator)
			v_i32 := [2]i32{i32(v[0]), i32(v[1])}
			ret := im.DragInt2(
				label_cstr,
				&v_i32,
				v_speed,
				i32(v_min),
				i32(v_max),
				format_cstr,
				flags,
			)
			v^ = [2]u32{u32(v_i32[0]), u32(v_i32[1])}
			return ret
		},
		drag_uint3 = proc(
			data: rawptr,
			label: string,
			v: ^[3]u32,
			v_speed: f32 = 1,
			v_min: u32 = 0,
			v_max: u32 = 0,
			format: string = "%u",
			flags: ui_slider_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			format_cstr := strings.clone_to_cstring(format, context.temp_allocator)
			v_i32 := [3]i32{i32(v[0]), i32(v[1]), i32(v[2])}
			ret := im.DragInt3(
				label_cstr,
				&v_i32,
				v_speed,
				i32(v_min),
				i32(v_max),
				format_cstr,
				flags,
			)
			v^ = [3]u32{u32(v_i32[0]), u32(v_i32[1]), u32(v_i32[2])}
			return ret
		},
		drag_float = proc(
			data: rawptr,
			label: string,
			v: ^fp,
			v_speed: fp = 1.0,
			v_min: fp = 0.0,
			v_max: fp = 0.0,
			format: string = "%.3f",
			flags: ui_slider_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			format_cstr := strings.clone_to_cstring(format, context.temp_allocator)
			return im.DragFloat(label_cstr, v, v_speed, v_min, v_max, format_cstr, flags)
		},
		drag_float2 = proc(
			data: rawptr,
			label: string,
			v: ^[2]fp,
			v_speed: fp = 1.0,
			v_min: fp = 0.0,
			v_max: fp = 0.0,
			format: string = "%.3f",
			flags: ui_slider_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			format_cstr := strings.clone_to_cstring(format, context.temp_allocator)
			return im.DragFloat2(label_cstr, v, v_speed, v_min, v_max, format_cstr, flags)
		},
		drag_float3 = proc(
			data: rawptr,
			label: string,
			v: ^[3]fp,
			v_speed: fp = 1.0,
			v_min: fp = 0.0,
			v_max: fp = 0.0,
			format: string = "%.3f",
			flags: ui_slider_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			format_cstr := strings.clone_to_cstring(format, context.temp_allocator)
			return im.DragFloat3(label_cstr, v, v_speed, v_min, v_max, format_cstr, flags)
		},
		checkbox = proc(data: rawptr, label: string, v: ^bool) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			return im.Checkbox(label_cstr, v)
		},
		dockspace_over_viewport = proc(data: rawptr, id: string, flags: ui_dock_node_flags = {}) {
			id_cstr := strings.clone_to_cstring(id, context.temp_allocator)
			im.DockSpaceOverViewport(im.GetID(id_cstr), {}, flags)
		},
		input_text = proc(
			data: rawptr,
			label: string,
			buf: ^string,
			flags: ui_input_text_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			buf_cstr := strings.clone_to_cstring(buf^, context.temp_allocator)
			if buf_cstr == nil {
				return false
			}
			ret := im.InputText(label_cstr, buf_cstr, cstring_buffers_length, flags)
			if ret {
				buf^ = strings.clone_from_cstring(buf_cstr)
			}
			return ret
		},
	}
}

imgui_main_menu_bar_update_step :: struct {
	using step: app_step,
}

imgui_update_step :: struct {
	using step: app_step,
}

imgui_plugin :: proc(app: ^app) {
	im.CHECKVERSION()
	im.CreateContext()

	io := im.GetIO()
	io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad, .DockingEnable, .ViewportsEnable}
	style := im.GetStyle()
	style.WindowRounding = 0
	style.Colors[im.Col.WindowBg].w = 1
	im.StyleColorsDark()

	imrl.init()
	imrl.build_font_atlas()

	app_set_resource(app, imgui_ui())
	app_set_resource(app, imgui_main_menu_bar_ui())
	app_add_systems(app, rendering_step, imgui_update_system)
	app_add_systems(app, deinit_step, imgui_deinit_system)
}

imgui_update_system :: proc(#by_ptr step: rendering_step) {
	imrl.process_events()
	imrl.new_frame()
	im.NewFrame()

	if im.BeginMainMenuBar() {
		scheduler_dispatch(
			step.scheduler,
			imgui_main_menu_bar_update_step,
			imgui_main_menu_bar_update_step{step = step},
		)
		im.EndMainMenuBar()
	}

	scheduler_dispatch(step.scheduler, imgui_update_step, imgui_update_step{step = step})
	im.Render()
	imrl.render_draw_data(im.GetDrawData())
	im.UpdatePlatformWindows()
	im.RenderPlatformWindowsDefault()
}

imgui_deinit_system :: proc(#by_ptr step: deinit_step) {
	imrl.shutdown()
	im.DestroyContext()
}
