package tyr

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:reflect"

name :: distinct string

entity_selection :: struct {
	is_entity_selected: bool,
	selected_entity:    entity,
}

type_drawer :: proc(ui: ^ui, obj: rawptr)
editor :: struct {
	type_drawers: map[typeid]type_drawer,
	selection:    entity_selection,
}

editor_register_drawer :: proc(res: ^resources, $t: typeid, drawer: proc(ui: ^ui, obj: rawptr)) {
	editor, ok := resources_get(res, editor)
	if !ok {return}
	editor.type_drawers[t] = drawer
}

editor_step :: struct {
	using ui_step: ui_step,
	editor:        ^editor,
}


editor_plugin :: proc(app: ^app) {
	app_add_plugins(app, ui_plugin)
	resources_set(&app.resources, editor{})
	app_add_plugins(app, editor_drawers_plugin)
	app_add_systems(app, ui_step, editor_update_system)
	app_add_systems(
		app,
		editor_step,
		editor_scene_window_system,
		editor_resources_window_system,
		editor_inspector_window_system,
	)
}

editor_update_system :: proc(#by_ptr step: ui_step) {
	editor, ok := resources_get(step.resources, editor)
	if !ok {
		return
	}
	ui_dockspace_over_viewport(step.ui, "tyr_editor_dockspace", {.passthru_central_node})
	scheduler_dispatch(step.scheduler, editor_step, editor_step{ui_step = step, editor = editor})
}

editor_scene_window_system :: proc(#by_ptr step: editor_step) {
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
				step.editor.selection.is_entity_selected &&
				e == step.editor.selection.selected_entity
			if ui_selectable(step.ui, label, is_selected) {
				step.editor.selection.is_entity_selected = true
				step.editor.selection.selected_entity = e
			}
		}
	}
	ui_end_window(step.ui)
}


editor_resources_window_system :: proc(#by_ptr step: editor_step) {
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

editor_draw_obj :: proc(#by_ptr step: editor_step, type: typeid, obj: rawptr) {
	drawer, ok := step.editor.type_drawers[type]
	if ok {
		drawer(step.ui, obj)
		return
	}

	type_info := type_info_of(type)
	type_info_named, is_named := type_info.variant.(runtime.Type_Info_Named)

	if !is_named {return}
	type_info_struct, is_struct := type_info_named.base.variant.(runtime.Type_Info_Struct)
	if !is_struct {return}
	field_names := reflect.struct_field_names(type)
	field_type_infos := reflect.struct_field_types(type)
	field_tags := reflect.struct_field_tags(type)
	for field_name, i in field_names {
		field_type_info := field_type_infos[i]
		field_tag := field_tags[i]
		field := reflect.struct_field_by_name(type, field_name)

		obj_deref_able_ptr := cast([^]type_of(obj))obj
		if obj_deref_able_ptr == nil {continue}
		field_obj := mem.ptr_offset(obj_deref_able_ptr, field.offset)
		if field_obj == nil {continue}
		if ui_tree_node(step.ui, field_name) {
			editor_draw_obj(step, field_type_info.id, field_obj)
			ui_tree_pop(step.ui)
		}
	}
}

editor_inspector_window_system :: proc(#by_ptr step: editor_step) {
	if ui_begin_window(step.ui, "Inspector") {
		if step.editor.selection.is_entity_selected &&
		   ecs_entity_is_valid(step.ecs_ctx, step.editor.selection.selected_entity) {
			for info in ecs_get_components_of_entity(
				step.ecs_ctx,
				step.editor.selection.selected_entity, context.temp_allocator
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
