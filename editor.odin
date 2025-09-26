package tyr

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:mem"
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

editor_type_inspector :: proc(ui: ^ui, obj: rawptr)

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

editor_main_menu_bar_system :: proc(#by_ptr step: ui_main_menu_bar_update_step) {
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

editor_update_system :: proc(#by_ptr step: ui_update_step) {
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

editor_scene_window_system :: proc(#by_ptr step: editor_update_step) {
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

editor_game_window_system :: proc(#by_ptr step: editor_update_step) {
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


editor_resources_window_system :: proc(#by_ptr step: editor_update_step) {
	if ui_begin_window(step.ui, "Resources") {
		for res_type, &res_val in step.resources {
			label := fmt.tprintf("%s", res_type)
			if ui_tree_node(step.ui, label) {
				editor_update_step_render_inspector(step, res_type, res_val)
				ui_tree_pop(step.ui)
			}

		}
	}
	ui_end_window(step.ui)
}

editor_has_inspector :: proc(editor: ^editor_state, type: typeid) -> bool {
	type_has_inspector := type in editor.type_inspectors
	if type_has_inspector {return true}
	type_info := type_info_of(type)
	#partial switch v in type_info.variant {
	case runtime.Type_Info_Named:
		type_info_named := type_info.variant.(runtime.Type_Info_Named)
		base_has_inspector := editor_has_inspector(editor, type_info_named.base.id)
		if base_has_inspector {return true}
	case runtime.Type_Info_Struct:
		type_info_struct := type_info.variant.(runtime.Type_Info_Struct)
		field_type_infos := type_info_struct.types
		for i in 0 ..< type_info_struct.field_count {
			field_type_info := field_type_infos[i]
			if editor_has_inspector(editor, field_type_info.id) {return true}
		}
	case runtime.Type_Info_Array:
		type_info_arr := type_info.variant.(runtime.Type_Info_Array)
		if editor_has_inspector(editor, type_info_arr.elem.id) {return true}
	}


	return false
}

editor_update_step_render_inspector :: proc(
	#by_ptr step: editor_update_step,
	type: typeid,
	obj: rawptr,
) {
	drawer, ok := step.editor_state.type_inspectors[type]
	if ok {
		drawer(step.ui, obj)
		return
	}

	type_info := type_info_of(type)
	#partial switch v in type_info.variant {
	case runtime.Type_Info_Named:
		type_info_named := type_info.variant.(runtime.Type_Info_Named)
		#partial switch v in type_info_named.base.variant {
		case runtime.Type_Info_Enum:
			type_info_enum := type_info_named.base.variant.(runtime.Type_Info_Enum)
			// TODO dropdown
			obj_any := any{obj, type}
			enum_name, ok := reflect.enum_name_from_value_any(obj_any)
			ui_input_text(step.ui, "##", &enum_name, {.ReadOnly})
		case runtime.Type_Info_Dynamic_Array:
			type_info_dyn_arr := type_info_named.base.variant.(runtime.Type_Info_Dynamic_Array)
		// TODO list (with add button/remove buttons)
		case runtime.Type_Info_Struct:
			type_info_struct := type_info_named.base.variant.(runtime.Type_Info_Struct)

			field_type_infos := type_info_struct.types
			field_names := reflect.struct_field_names(type)
			field_tags := type_info_struct.tags
			field_count := len(field_names)

			for i in 0 ..< type_info_struct.field_count {
				field_type_info := field_type_infos[i]
				if !editor_has_inspector(step.editor_state, field_type_info.id) {continue}

				field_name := field_names[i]
				field_tag := field_tags[i]
				field := reflect.struct_field_by_name(type, field_name)
				obj_any := any{obj, type}
				field_value_any := reflect.struct_field_value(obj_any, field)
				if field_value_any == nil {continue}

				if ui_tree_node(step.ui, field_name) {
					editor_update_step_render_inspector(
						step,
						field_value_any.id,
						field_value_any.data,
					)
					ui_tree_pop(step.ui)
				}
			}
		}
		if type_info_named.base != nil &&
		   editor_has_inspector(step.editor_state, type_info_named.base.id) {
			editor_update_step_render_inspector(step, type_info_named.base.id, obj)
		}
	case runtime.Type_Info_Array:
		type_info_arr := type_info.variant.(runtime.Type_Info_Array)
		if (editor_has_inspector(step.editor_state, type_info_arr.elem.id)) {
			arr_ptr := cast([^]byte)(obj)
			for i in 0 ..< type_info_arr.count {
				elem_ptr := rawptr(uintptr(arr_ptr) + uintptr(i * type_info_arr.elem_size))
				editor_update_step_render_inspector(step, type_info_arr.elem.id, elem_ptr)
			}
		}
	}
}

editor_inspector_window_system :: proc(#by_ptr step: editor_update_step) {
	if ui_begin_window(step.ui, "Inspector") {
		if step.editor_state.selection.is_entity_selected &&
		   ecs_is_entity_valid(step.ecs_ctx, step.editor_state.selection.selected_entity) {
			for info in ecs_get_components_of_entity(
				step.ecs_ctx,
				step.editor_state.selection.selected_entity,
				context.temp_allocator,
			) {
				if info.data == nil {
					continue
				}
				label := fmt.tprintf("%s", info.id)
				if ui_tree_node(step.ui, label) {
					editor_update_step_render_inspector(step, info.id, info.data)
					ui_tree_pop(step.ui)
				}
			}
		}
	}
	ui_end_window(step.ui)
}
