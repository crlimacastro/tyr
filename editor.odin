package tyr

import "base:runtime"
import "core:fmt"
import "core:math/linalg"
import "core:reflect"

editor_transform_mode :: enum {
	select,
	translate,
	rotate,
	scale,
}

editor_entity_selection :: struct {
	is_entity_selected: bool,
	selected_entity:    entity,
}

editor_type_inspector :: proc(ui: ^ui, ptr: rawptr, info: ^reflect.Type_Info)

editor_state :: struct {
	type_inspectors: map[typeid]editor_type_inspector,
	selection:       editor_entity_selection,
	transform_mode:  editor_transform_mode,
	open_scenes:     [dynamic]scene,
}

editor_state_register_inspector :: proc(
	res: ^resources,
	$t: typeid,
	drawer: editor_type_inspector,
) {
	editor, ok := resources_get(res, editor_state)
	if !ok {return}
	editor.type_inspectors[t] = drawer
}

editor_update_step :: struct {
	using ui_step: ui_update_step,
	editor_state:  ^editor_state,
}


editor_plugin :: proc(app: ^app) {
	create_dot_tyr_dir()
	app_add_plugins(app, ui_plugin)
	resources_set(&app.resources, editor_state{})
	app_add_plugins(app, editor_inspectors_plugin)
	app_add_systems(app, ui_main_menu_bar_update_step, editor_main_menu_bar_system)
	app_add_systems(app, ui_update_step, editor_update_system)
	app_add_systems(
		app,
		editor_update_step,
		editor_scene_window_system,
		// editor_game_window_system,
		editor_resources_window_system,
		editor_inspector_window_system,
	)
}

editor_main_menu_bar_system :: proc(step: ui_main_menu_bar_update_step) {
	if main_menu_bar_ui_begin_menu(step.ui, "File") {
		if main_menu_bar_ui_menu_item(step.ui, "New Project") {
			for entity in ecs_get_entities(step.ecs_ctx, context.temp_allocator) {
				ecs_destroy_entity(step.ecs_ctx, entity)
			}
		}

		if main_menu_bar_ui_menu_item(step.ui, "Quit") {
			scheduler_dispatch(step.scheduler, app_quit, app_quit{})
		}
		main_menu_bar_ui_end_menu(step.ui)
	}

	if main_menu_bar_ui_begin_menu(step.ui, "Edit") {
		if main_menu_bar_ui_menu_item(step.ui, "Undo") {
			// TODO
		}

		if main_menu_bar_ui_menu_item(step.ui, "Redo") {
			// TODO
		}

		main_menu_bar_ui_end_menu(step.ui)
	}

}

editor_update_system :: proc(step: ui_update_step) {
	state, ok := resources_get(step.resources, editor_state)
	if !ok {
		return
	}
	ui_dockspace_over_viewport(step.ui, "tyr_editor_dockspace", {.PassthruCentralNode})
	scheduler_dispatch(
		step.scheduler,
		editor_update_step,
		editor_update_step{ui_step = step, editor_state = state},
	)
}

editor_scene_window_system :: proc(step: editor_update_step) {
	if ui_begin_window(step.ui, "Scene") {
		input, ok := resources_get(step.resources, input)
		if ok {
			if input_is_key_pressed(input, .ESCAPE) {
				step.editor_state.selection.is_entity_selected = false
			}
		}

		for e in ecs_get_entities(step.ecs_ctx, context.temp_allocator) {
			label := fmt.tprint(e)
			{
				name, ok := ecs_get_component(step.ecs_ctx, e, name)
				if ok {
					label = fmt.tprintf("%s (%s)", name^, label)
				}
			}

			is_selected :=
				step.editor_state.selection.is_entity_selected &&
				e == step.editor_state.selection.selected_entity
			if ui_selectable(step.ui, label, is_selected) {
				step.editor_state.selection.is_entity_selected = true
				step.editor_state.selection.selected_entity = e
			}
		}

		if ok {
			if input_is_key_pressed(input, .DELETE) &&
			   step.editor_state.selection.is_entity_selected {
				ecs_destroy_entity(step.ecs_ctx, step.editor_state.selection.selected_entity)
				step.editor_state.selection.is_entity_selected = false
			}
		}
	}
	ui_end_window(step.ui)
}

editor_game_window_system :: proc(step: editor_update_step) {
	input, ok := resources_get(step.resources, input)
	if !ok {return}

	if ui_begin_window(step.ui, "Game", nil, {.NoBackground, .NoTitleBar}) {
		game_window_button_info :: struct {
			label: string,
			key:   keyboard_key,
			mode:  editor_transform_mode,
		}
		buttons := [?]game_window_button_info {
			{label = "Select   ", key = .Q, mode = .select},
			{label = "Translate", key = .W, mode = .translate},
			{label = "Rotate   ", key = .E, mode = .rotate},
			{label = "Scale    ", key = .R, mode = .scale},
		}
		for btn in buttons {
			label := fmt.tprintf("%s  ", btn.label)
			if step.editor_state.transform_mode == btn.mode {
				label = fmt.tprintf("%s *", btn.label)
			}
			if ui_button(step.ui, label) || input_is_key_pressed(input, btn.key) {
				step.editor_state.transform_mode = btn.mode
			}
		}
	}
	ui_end_window(step.ui)
}


editor_resources_window_system :: proc(step: editor_update_step) {
	if ui_begin_window(step.ui, "Resources") {
		for res_type, &res_val in step.resources {
			label := fmt.tprintf("%s", res_type)
			if ui_tree_node(step.ui, label, {.DefaultOpen}) {
				editor_update_step_render_inspector(step, res_val, type_info_of(res_type))
				ui_tree_pop(step.ui)
			}

		}
	}
	ui_end_window(step.ui)
}

editor_update_step_render_inspector :: proc(
	step: editor_update_step,
	ptr: rawptr,
	info: ^reflect.Type_Info,
) {
	drawer, ok := step.editor_state.type_inspectors[info.id]
	if ok {
		drawer(step.ui, ptr, info)
		return
	}

	#partial switch v in info.variant {
	case runtime.Type_Info_Named:
		editor_update_step_render_inspector(step, ptr, v.base)
	case runtime.Type_Info_Integer:
		if v.signed {
			switch info.size {
			case size_of(i16):
				val := cast(^i16)ptr
				val_i32 := cast(i32)val^
				ui_drag_int(step.ui, "##", &val_i32, v_min = i32(min(i16)), v_max = i32(max(i16)))
				val^ = cast(i16)val_i32
			case size_of(i32):
				val := cast(^i32)ptr
				ui_drag_int(step.ui, "##", val)
			case size_of(i64):
				val := cast(^i64)ptr
				val_i32 := cast(i32)val^
				ui_drag_int(step.ui, "##", &val_i32)
				val^ = cast(i64)val_i32
			case size_of(i128):
				val := cast(^i128)ptr
				val_i32 := cast(i32)val^
				ui_drag_int(step.ui, "##", &val_i32)
				val^ = cast(i128)val_i32
			case:
				unreachable()
			}
		} else {
			switch info.size {
			case size_of(u16):
				val := cast(^u16)ptr
				val_u32 := cast(u32)val^
				ui_drag_uint(step.ui, "##", &val_u32, v_min = u32(min(u16)), v_max = u32(max(u16)))
				val^ = cast(u16)val_u32
			case size_of(u32):
				val := cast(^u32)ptr
				ui_drag_uint(step.ui, "##", val)
			case size_of(u64):
				val := cast(^u64)ptr
				val_u32 := cast(u32)val^
				ui_drag_uint(step.ui, "##", &val_u32)
				val^ = cast(u64)val_u32
			case size_of(u128):
				val := cast(^u128)ptr
				val_i32 := cast(i32)val^
				ui_drag_int(step.ui, "##", &val_i32)
				val^ = cast(u128)val_i32
			case:
				unreachable()
			}
		}
	case runtime.Type_Info_Rune:
		val := cast(^rune)ptr
		ui_input_rune(step.ui, "##", val)
	case runtime.Type_Info_Float:
		switch info.size {
		case size_of(f16):
			val := cast(^f16)ptr
			val_f32 := cast(f32)val^
			ui_drag_float(step.ui, "##", &val_f32, v_min = f32(min(f16)), v_max = f32(max(f16)))
			val^ = cast(f16)val_f32
		case size_of(f32):
			val := cast(^f32)ptr
			ui_drag_float(step.ui, "##", val)
		case size_of(f64):
			val := cast(^f64)ptr
			val_f32 := cast(f32)val^
			ui_drag_float(step.ui, "##", &val_f32)
			val^ = cast(f64)val_f32
		case:
			unreachable()
		}
	// case runtime.Type_Info_Complex:
	case runtime.Type_Info_Quaternion:
		switch info.size {
		case size_of(quaternion64):
			val := cast(^quaternion64)ptr
			val_quaternion128 := cast(quaternion128)val^
			x, y, z := linalg.euler_angles_xyz_from_quaternion(val_quaternion128)
			euler_fp := [?]fp{x, y, z} * linalg.DEG_PER_RAD
			ui_drag_float3(step.ui, "##", &euler_fp, v_min = f32(min(f16)), v_max = f32(max(f16)))
			euler_fp = euler_fp * linalg.RAD_PER_DEG
			dst := linalg.quaternion_from_euler_angles(euler_fp.x, euler_fp.y, euler_fp.z, .XYZ)
			val^ = cast(quaternion64)dst
		case size_of(quaternion128):
			val := cast(^quaternion128)ptr
			x, y, z := linalg.euler_angles_xyz_from_quaternion(val^)
			euler_fp := [?]fp{x, y, z} * linalg.DEG_PER_RAD
			ui_drag_float3(step.ui, "##", &euler_fp)
			euler_fp = euler_fp * linalg.RAD_PER_DEG
			dst := linalg.quaternion_from_euler_angles(euler_fp.x, euler_fp.y, euler_fp.z, .XYZ)
			val^ = dst
		case size_of(quaternion256):
			val := cast(^quaternion256)ptr
			val_quaternion128 := cast(quaternion128)val^
			x, y, z := linalg.euler_angles_xyz_from_quaternion(val_quaternion128)
			euler_fp := [?]fp{x, y, z} * linalg.DEG_PER_RAD
			ui_drag_float3(step.ui, "##", &euler_fp)
			euler_fp = euler_fp * linalg.RAD_PER_DEG
			dst := linalg.quaternion_from_euler_angles(euler_fp.x, euler_fp.y, euler_fp.z, .XYZ)
			val^ = cast(quaternion256)dst
		case:
			unreachable()
		}
	case runtime.Type_Info_String:
		val := cast(^string)ptr
		ui_input_text(step.ui, "##", val)
	case runtime.Type_Info_Boolean:
		val := cast(^bool)ptr
		ui_checkbox(step.ui, "##", val)
	// case runtime.Type_Info_Any:
	// case runtime.Type_Info_Type_Id:
	// case runtime.Type_Info_Pointer:
	// case runtime.Type_Info_Multi_Pointer:
	// case runtime.Type_Info_Procedure:
	case runtime.Type_Info_Array:
		for i in 0 ..< v.count {
			ui_push_id(step.ui, tprintf("%v", i))
			elem_ptr := rawptr(uintptr(ptr) + uintptr(i * v.elem_size))
			editor_update_step_render_inspector(step, elem_ptr, v.elem)
			ui_pop_id(step.ui)
		}
	// case runtime.Type_Info_Enumerated_Array:
	// case runtime.Type_Info_Dynamic_Array:
	// TODO list (with add/remove buttons)
	// case runtime.Type_Info_Slice:
	// case runtime.Type_Info_Parameters:
	case runtime.Type_Info_Struct:
		for i in 0 ..< v.field_count {
			field_ptr := rawptr(uintptr(ptr) + uintptr(v.offsets[i]))
			ui_push_id(step.ui, v.names[i])
			if ui_tree_node(step.ui, v.names[i], {.DefaultOpen}) {
				editor_update_step_render_inspector(step, field_ptr, v.types[i])
				ui_tree_pop(step.ui)
			}
			ui_pop_id(step.ui)
		}
	// case runtime.Type_Info_Union:
	case runtime.Type_Info_Enum:
		// TODO dropdown
		ptr_any := any{ptr, info.id}
		enum_name, ok := reflect.enum_name_from_value_any(ptr_any)
		if ok {
			ui_input_text(step.ui, "##", &enum_name, {.ReadOnly})
		}
	// case runtime.Type_Info_Map:
	// case runtime.Type_Info_Bit_Set:
	// case runtime.Type_Info_Simd_Vector:
	// case runtime.Type_Info_Matrix:
	// case runtime.Type_Info_Soa_Pointer:
	// case runtime.Type_Info_Bit_Field:
	// case runtime.Type_Info_Fixed_Capacity_Dynamic_Array:
	case:
		ui_text(step.ui, fmt.tprintf("TODO: %v", info))
	}
}

editor_inspector_window_system :: proc(step: editor_update_step) {
	if ui_begin_window(step.ui, "Inspector") {
		if step.editor_state.selection.is_entity_selected &&
		   ecs_is_entity_valid(step.ecs_ctx, step.editor_state.selection.selected_entity) {
			for component in ecs_get_components_of_entity(step.ecs_ctx, step.editor_state.selection.selected_entity, context.temp_allocator) {
				if component.data == nil {
					continue
				}
				label := fmt.tprintf("%s", component.id)
				ui_push_id(step.ui, label)
				if ui_tree_node(step.ui, label, {.DefaultOpen}) {
					editor_update_step_render_inspector(
						step,
						component.data,
						type_info_of(component.id),
					)
					ui_tree_pop(step.ui)
				}
				ui_pop_id(step.ui)
			}
		}
	}
	ui_end_window(step.ui)
}
