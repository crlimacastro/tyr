package tyr

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:reflect"

name :: distinct string

transformation_mode :: enum {
	select,
	translate,
	rotate,
	scale,
}

entity_selection :: struct {
	is_entity_selected: bool,
	selected_entity:    entity,
}

type_inspector :: proc(ui: ^ui, obj: rawptr)
editor_state :: struct {
	type_inspectors:   map[typeid]type_inspector,
	selection:      entity_selection,
	transform_mode: transformation_mode,
}

editor_state_register_inspector :: proc(res: ^resources, $t: typeid, drawer: type_inspector) {
	editor, ok := resources_get(res, editor_state)
	if !ok {return}
	editor.type_inspectors[t] = drawer
}

editor_update_step :: struct {
	using ui_step: ui_step,
	editor_state:        ^editor_state,
}


editor_plugin :: proc(app: ^app) {
	app_add_plugins(app, ui_plugin)
	resources_set(&app.resources, editor_state{})
	app_add_plugins(app, editor_inspectors_plugin)
	app_add_systems(app, ui_step, editor_update_system)
	app_add_systems(
		app,
		editor_update_step,
		editor_scene_window_system,
		// editor_game_window_system,
		editor_resources_window_system,
		editor_inspector_window_system,
	)
}

editor_update_system :: proc(#by_ptr step: ui_step) {
	state, ok := resources_get(step.resources, editor_state)
	if !ok {
		return
	}
	ui_dockspace_over_viewport(step.ui, "tyr_editor_dockspace", {.passthru_central_node})
	scheduler_dispatch(step.scheduler, editor_update_step, editor_update_step{ui_step = step, editor_state = state})
}

editor_scene_window_system :: proc(#by_ptr step: editor_update_step) {
	if ui_begin_window(step.ui, "Scene") {
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
	}
	ui_end_window(step.ui)
}

editor_game_window_system :: proc(#by_ptr step: editor_update_step) {
	input, ok := resources_get(step.resources, input)
	if !ok {return}

	if ui_begin_window(step.ui, "Game", nil, {.no_background, .no_title_bar}) {
		game_window_button_info :: struct {
			label: string,
			key:   keyboard_key,
			mode: transformation_mode
		}
		buttons := [?]game_window_button_info {
			{label = "Select   ", key = .q, mode=.select},
			{label = "Translate", key = .w, mode=.translate},
			{label = "Rotate   ", key = .e, mode=.rotate},
			{label = "Scale    ", key = .r, mode=.scale},
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
				editor_draw_obj(step, res_type, res_val)
				ui_tree_pop(step.ui)
			}

		}
	}
	ui_end_window(step.ui)
}

editor_draw_obj :: proc(#by_ptr step: editor_update_step, type: typeid, obj: rawptr) {
	drawer, ok := step.editor_state.type_inspectors[type]
	if ok {
		drawer(step.ui, obj)
		return
	}

	type_info := type_info_of(type)
	type_info_named, is_named := type_info.variant.(runtime.Type_Info_Named)

	if !is_named {return}

	type_info_enum, is_enum := type_info_named.base.variant.(runtime.Type_Info_Enum)
	if is_enum {
		obj_any := any{obj, type}
		enum_name, ok := reflect.enum_name_from_value_any(obj_any)
		ui_input_text(step.ui, "##", &enum_name, {.read_only})
		return
	}

	type_info_struct, is_struct := type_info_named.base.variant.(runtime.Type_Info_Struct)
	if is_struct {
		field_names := reflect.struct_field_names(type)
		field_type_infos := reflect.struct_field_types(type)
		field_tags := reflect.struct_field_tags(type)
		for field_name, i in field_names {
			field_type_info := field_type_infos[i]
			
			type_info_procedure, is_procedure := field_type_info.variant.(runtime.Type_Info_Procedure)
			if is_procedure {
				continue
			}
	
			field_tag := field_tags[i]
			field := reflect.struct_field_by_name(type, field_name)
	
			obj_any := any{obj, type}
			field_val_any := reflect.struct_field_value(obj_any, field)
			if field_val_any == nil {continue}
			if ui_tree_node(step.ui, field_name) {
				editor_draw_obj(step, field_type_info.id, field_val_any.data)
				ui_tree_pop(step.ui)
			}
		}
		return
	}

	if type_info_named.base != nil {
		editor_draw_obj(step, type_info_named.base.id, obj)
	}
}

editor_inspector_window_system :: proc(#by_ptr step: editor_update_step) {
	if ui_begin_window(step.ui, "Inspector") {
		if step.editor_state.selection.is_entity_selected &&
		   ecs_entity_is_valid(step.ecs_ctx, step.editor_state.selection.selected_entity) {
			for info in ecs_get_components_of_entity(
				step.ecs_ctx,
				step.editor_state.selection.selected_entity,
				context.temp_allocator,
			) {
				label := fmt.tprintf("%s", info.id)
				if ui_tree_node(step.ui, label) {
					editor_draw_obj(step, info.id, info.ptr)
					ui_tree_pop(step.ui)
				}
			}
		}
	}
	ui_end_window(step.ui)
}
