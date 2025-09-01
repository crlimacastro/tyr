package tyr

main_menu_bar_ui :: struct {
	data:       rawptr,
	begin_menu: proc(data: rawptr, label: string) -> bool,
	end_menu:   proc(data: rawptr),
	menu_item:  proc(data: rawptr, label: string) -> bool,
}

main_menu_bar_ui_begin_menu :: proc(ui: ^main_menu_bar_ui, label: string) -> bool {
	return ui.begin_menu(ui.data, label)
}

main_menu_bar_ui_end_menu :: proc(ui: ^main_menu_bar_ui) {
	ui.end_menu(ui.data)
}

main_menu_bar_ui_menu_item :: proc(ui: ^main_menu_bar_ui, label: string) -> bool {
	return ui.menu_item(ui.data, label)
}

ui :: struct {
	data:                    rawptr,
	begin_window:            proc(
		data: rawptr,
		name: string,
		open: ^bool,
		flags: ui_window_flags,
	) -> bool,
	end_window:              proc(data: rawptr),
	button:                  proc(data: rawptr, label: string) -> bool,
	selectable:              proc(
		data: rawptr,
		label: string,
		selected: bool = false,
		flags: ui_selectable_flags = {},
		size: vec2,
	) -> bool,
	tree_node:               proc(data: rawptr, label: string) -> bool,
	tree_pop:                proc(data: rawptr),
	color_edit_4:            proc(
		data: rawptr,
		label: string,
		col: ^[4]fp,
		flags: ui_color_edit_flags = {},
	) -> bool,
	drag_int:                proc(
		data: rawptr,
		label: string,
		v: ^i32,
		v_speed: f32 = 1,
		v_min: i32 = 0,
		v_max: i32 = 0,
		format: string = "%d",
		flags: ui_slider_flags = {},
	) -> bool,
	drag_int2:               proc(
		data: rawptr,
		label: string,
		v: ^[2]i32,
		v_speed: f32 = 1,
		v_min: i32 = 0,
		v_max: i32 = 0,
		format: string = "%d",
		flags: ui_slider_flags = {},
	) -> bool,
	drag_int3:               proc(
		data: rawptr,
		label: string,
		v: ^[3]i32,
		v_speed: f32 = 1,
		v_min: i32 = 0,
		v_max: i32 = 0,
		format: string = "%d",
		flags: ui_slider_flags = {},
	) -> bool,
	drag_uint:               proc(
		data: rawptr,
		label: string,
		v: ^u32,
		v_speed: f32 = 1,
		v_min: u32 = 0,
		v_max: u32 = 0,
		format: string = "%u",
		flags: ui_slider_flags = {},
	) -> bool,
	drag_uint2:              proc(
		data: rawptr,
		label: string,
		v: ^[2]u32,
		v_speed: f32 = 1,
		v_min: u32 = 0,
		v_max: u32 = 0,
		format: string = "%u",
		flags: ui_slider_flags = {},
	) -> bool,
	drag_uint3:              proc(
		data: rawptr,
		label: string,
		v: ^[3]u32,
		v_speed: f32 = 1,
		v_min: u32 = 0,
		v_max: u32 = 0,
		format: string = "%u",
		flags: ui_slider_flags = {},
	) -> bool,
	drag_float:              proc(
		data: rawptr,
		label: string,
		v: ^fp,
		v_speed: fp = 1.0,
		v_min: fp = 0.0,
		v_max: fp = 0.0,
		format: string = "%.3f",
		flags: ui_slider_flags = {},
	) -> bool,
	drag_float2:             proc(
		data: rawptr,
		label: string,
		v: ^[2]fp,
		v_speed: fp = 1.0,
		v_min: fp = 0.0,
		v_max: fp = 0.0,
		format: string = "%.3f",
		flags: ui_slider_flags = {},
	) -> bool,
	drag_float3:             proc(
		data: rawptr,
		label: string,
		v: ^[3]fp,
		v_speed: fp = 1.0,
		v_min: fp = 0.0,
		v_max: fp = 0.0,
		format: string = "%.3f",
		flags: ui_slider_flags = {},
	) -> bool,
	checkbox:                proc(data: rawptr, label: string, v: ^bool) -> bool,
	dockspace_over_viewport: proc(data: rawptr, id: string, flags: ui_dock_node_flags = {}),
	input_text:              proc(
		data: rawptr,
		label: string,
		buf: ^string,
		flags: ui_input_text_flags = {},
	) -> bool,
}

ui_begin_window :: proc(
	ui: ^ui,
	name: string,
	open: ^bool = nil,
	flags: ui_window_flags = {},
) -> bool {
	return ui.begin_window(ui.data, name, open, flags)
}

ui_end_window :: proc(ui: ^ui) {
	ui.end_window(ui.data)
}

ui_button :: proc(ui: ^ui, label: string) -> bool {
	return ui.button(ui.data, label)
}

ui_selectable :: proc(
	ui: ^ui,
	label: string,
	selected: bool = false,
	flags: ui_selectable_flags = {},
	size: vec2 = {0, 0},
) -> bool {
	return ui.selectable(ui.data, label, selected, flags, size)
}

ui_tree_node :: proc(ui: ^ui, label: string) -> bool {
	return ui.tree_node(ui.data, label)
}

ui_tree_pop :: proc(ui: ^ui) {
	ui.tree_pop(ui.data)
}

ui_color_edit_4 :: proc(
	ui: ^ui,
	label: string,
	col: ^[4]fp,
	flags: ui_color_edit_flags = {},
) -> bool {
	return ui.color_edit_4(ui.data, label, col, flags)
}

ui_drag_uint :: proc(
	ui: ^ui,
	label: string,
	v: ^u32,
	v_speed: f32 = 1,
	v_min: u32 = 0,
	v_max: u32 = 0,
	format: string = "%u",
	flags: ui_slider_flags = {},
) -> bool {
	return ui.drag_uint(ui.data, label, v, v_speed, v_min, v_max, format, flags)
}

ui_drag_uint2 :: proc(
	ui: ^ui,
	label: string,
	v: ^[2]u32,
	v_speed: f32 = 1,
	v_min: u32 = 0,
	v_max: u32 = 0,
	format: string = "%u",
	flags: ui_slider_flags = {},
) -> bool {
	return ui.drag_uint2(ui.data, label, v, v_speed, v_min, v_max, format, flags)
}

ui_drag_uint3 :: proc(
	ui: ^ui,
	label: string,
	v: ^[3]u32,
	v_speed: f32 = 1,
	v_min: u32 = 0,
	v_max: u32 = 0,
	format: string = "%u",
	flags: ui_slider_flags = {},
) -> bool {
	return ui.drag_uint3(ui.data, label, v, v_speed, v_min, v_max, format, flags)
}

ui_drag_int :: proc(
	ui: ^ui,
	label: string,
	v: ^i32,
	v_speed: f32 = 1,
	v_min: i32 = 0,
	v_max: i32 = 0,
	format: string = "%d",
	flags: ui_slider_flags = {},
) -> bool {
	return ui.drag_int(ui.data, label, v, v_speed, v_min, v_max, format, flags)
}

ui_drag_int2 :: proc(
	ui: ^ui,
	label: string,
	v: ^[2]i32,
	v_speed: f32 = 1,
	v_min: i32 = 0,
	v_max: i32 = 0,
	format: string = "%d",
	flags: ui_slider_flags = {},
) -> bool {
	return ui.drag_int2(ui.data, label, v, v_speed, v_min, v_max, format, flags)
}

ui_drag_int3 :: proc(
	ui: ^ui,
	label: string,
	v: ^[3]i32,
	v_speed: f32 = 1,
	v_min: i32 = 0,
	v_max: i32 = 0,
	format: string = "%d",
	flags: ui_slider_flags = {},
) -> bool {
	return ui.drag_int3(ui.data, label, v, v_speed, v_min, v_max, format, flags)
}

ui_drag_float :: proc(
	ui: ^ui,
	label: string,
	v: ^fp,
	v_speed: fp = 1.0,
	v_min: fp = 0.0,
	v_max: fp = 0.0,
	format: string = "%.3f",
	flags: ui_slider_flags = {},
) -> bool {
	return ui.drag_float(ui.data, label, v, v_speed, v_min, v_max, format, flags)
}

ui_drag_float2 :: proc(
	ui: ^ui,
	label: string,
	v: ^[2]fp,
	v_speed: fp = 1.0,
	v_min: fp = 0.0,
	v_max: fp = 0.0,
	format: string = "%.3f",
	flags: ui_slider_flags = {},
) -> bool {
	return ui.drag_float2(ui.data, label, v, v_speed, v_min, v_max, format, flags)
}

ui_drag_float3 :: proc(
	ui: ^ui,
	label: string,
	v: ^[3]fp,
	v_speed: fp = 1.0,
	v_min: fp = 0.0,
	v_max: fp = 0.0,
	format: string = "%.3f",
	flags: ui_slider_flags = {},
) -> bool {
	return ui.drag_float3(ui.data, label, v, v_speed, v_min, v_max, format, flags)
}

ui_drag :: proc {
	ui_drag_uint,
	ui_drag_uint2,
	ui_drag_uint3,
	ui_drag_int,
	ui_drag_int2,
	ui_drag_int3,
	ui_drag_float,
	ui_drag_float2,
	ui_drag_float3,
}

ui_checkbox :: proc(ui: ^ui, label: string, v: ^bool) -> bool {
	return ui.checkbox(ui.data, label, v)
}

ui_main_menu_bar_update_step :: struct {
	using step: app_step,
	ui:         ^main_menu_bar_ui,
}

ui_update_step :: struct {
	using step: app_step,
	ui:         ^ui,
}

ui_plugin :: proc(app: ^app) {
	app_add_plugins(app, imgui_plugin)
	app_add_systems(app, imgui_main_menu_bar_update_step, ui_main_menu_bar_update_system)
	app_add_systems(app, imgui_update_step, ui_update_system)
}

ui_main_menu_bar_update_system :: proc(#by_ptr step: imgui_main_menu_bar_update_step) {
	ui, ok := resources_get(step.resources, main_menu_bar_ui)
	if !ok {
		return
	}
	scheduler_dispatch(
		step.scheduler,
		ui_main_menu_bar_update_step,
		ui_main_menu_bar_update_step{step = step, ui = ui},
	)
}

ui_update_system :: proc(#by_ptr step: imgui_update_step) {
	ui, ok := resources_get(step.resources, ui)
	if !ok {
		return
	}
	scheduler_dispatch(step.scheduler, ui_update_step, ui_update_step{step = step, ui = ui})
}

ui_dockspace_over_viewport :: proc(ui: ^ui, id: string, flags: ui_dock_node_flags = {}) {
	ui.dockspace_over_viewport(ui.data, id, flags)
}

ui_input_text :: proc(
	ui: ^ui,
	label: string,
	buf: ^string,
	flags: ui_input_text_flags = {},
) -> bool {
	return ui.input_text(ui.data, label, buf, flags)
}
