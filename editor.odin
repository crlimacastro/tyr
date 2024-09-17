package tyr

import "core:fmt"
import "core:reflect"
import "core:strings"
import ecs "odin-ecs"
import mu "vendor:microui"
import rl "vendor:raylib"

name :: distinct string

editor_step :: struct {
	using step: app_step,
	mu_ctx:     ^mu.Context,
}

editor_state :: struct {
	type_drawers:    map[typeid]proc(ctx: ^mu.Context, res: rawptr),
	selected_entity: ecs.Entity_And_Some_Info,
}

editor_register_drawer :: proc(
	res: ^resources,
	$t: typeid,
	drawer: proc(ctx: ^mu.Context, res: rawptr),
) {
	state, ok := resources_get(res, editor_state)
	if !ok {return}
	state.type_drawers[t] = drawer
}

editor_plugin :: proc(app: ^app) {
	app_add_plugins(app, ui_plugin)
	resources_set(&app.resources, editor_state, editor_state{})
	editor_register_drawer(&app.resources, clear_color, proc(ctx: ^mu.Context, res: rawptr) {
		clear_color := cast(^clear_color)res
		color_picker_rgb(ctx, &clear_color.r, &clear_color.g, &clear_color.b)
	})
	editor_register_drawer(&app.resources, editor_state, proc(ctx: ^mu.Context, res: rawptr) {
		state := cast(^editor_state)res
		label := "none"
		if state.selected_entity.is_valid {
			label = fmt.tprint(state.selected_entity.entity)
		}
		mu.layout_row(ctx, []i32{0, 0})
		mu.label(ctx, "selected entity:")
		mu.text(ctx, label)
	})
	editor_register_drawer(&app.resources, name, proc(ctx: ^mu.Context, res: rawptr) {
		n := cast(^name)res
		mu.text(ctx, string(n^))
	})
	editor_register_drawer(&app.resources, rl.Transform, proc(ctx: ^mu.Context, res: rawptr) {
		transform := cast(^rl.Transform)res
		mu.layout_row(ctx, []i32{0, 0, 0, 0})
		mu.label(ctx, "translation")
		mu.number(ctx, &transform.translation.x, 1.0)
		mu.number(ctx, &transform.translation.y, 1.0)
		mu.number(ctx, &transform.translation.z, 1.0)
		mu.label(ctx, "rotation")
		euler := rl.QuaternionToEuler(transform.rotation)
		euler *= rl.RAD2DEG
		mu.number(ctx, &euler.x, 1.0)
		mu.number(ctx, &euler.y, 1.0)
		mu.number(ctx, &euler.z, 1.0)
		euler *= rl.DEG2RAD
		transform.rotation = rl.QuaternionFromEuler(euler.x, euler.y, euler.z)
		mu.label(ctx, "scale")
		mu.number(ctx, &transform.scale.x, 0.01)
		mu.number(ctx, &transform.scale.y, 0.01)
		mu.number(ctx, &transform.scale.z, 0.01)
	})
	app_add_systems(app, ui_step, editor_update_system)
	app_add_systems(
		app,
		editor_step,
		editor_scene_window_system,
		editor_resources_window_system,
		editor_inspector_window_system,
	)
}

CONTEXT_MENU_HEIGHT_PERC :: 0.03
SCENE_WINDOW_WIDTH_PERC :: 0.2

editor_update_system :: proc(#by_ptr step: ui_step) {
	if mu.begin_window(
		step.mu_ctx,
		"Context Menu",
		{
			x = 0,
			y = 0,
			w = rl.GetScreenWidth(),
			h = i32(f32(rl.GetScreenHeight()) * CONTEXT_MENU_HEIGHT_PERC),
		},
		{.NO_INTERACT, .NO_CLOSE, .NO_RESIZE, .NO_TITLE},
	) {
		context_menu_button_width := i32(f32(rl.GetScreenWidth()) * 0)
		mu.layout_row(step.mu_ctx, []i32{context_menu_button_width, context_menu_button_width})
		if mu.button(step.mu_ctx, "File") == {.SUBMIT} {
			if mu.begin_popup(step.mu_ctx, "File") {
				if mu.button(step.mu_ctx, "Quit") == {.SUBMIT} {
					scheduler_dispatch(
						step.scheduler,
						app_quit,
						app_quit {
							scheduler = step.scheduler,
							resources = step.resources,
							ecs_ctx = step.ecs_ctx,
						},
					)
				}
				mu.end_popup(step.mu_ctx)
			}
			mu.open_popup(step.mu_ctx, "File")
		}
		if mu.button(step.mu_ctx, "Edit") == {.SUBMIT} {
		}

		mu.end_window(step.mu_ctx)
	}
	scheduler_dispatch(
		step.scheduler,
		editor_step,
		editor_step {
			resources = step.resources,
			scheduler = step.scheduler,
			mu_ctx = step.mu_ctx,
			ecs_ctx = step.ecs_ctx,
		},
	)
}

editor_scene_window_system :: proc(#by_ptr step: editor_step) {
	pad_top := i32(f32(rl.GetScreenHeight()) * CONTEXT_MENU_HEIGHT_PERC)
	scene_window_width := i32(f32(rl.GetScreenWidth()) * SCENE_WINDOW_WIDTH_PERC)
	scene_window_height := i32(f32(rl.GetScreenHeight()) * 1.0) - pad_top
	if mu.begin_window(
		step.mu_ctx,
		"Scene",
		{0, pad_top, scene_window_width, scene_window_height},
	) {
		mu.layout_begin_column(step.mu_ctx)
		mu.layout_row(step.mu_ctx, []i32{0})

		for e in step.ecs_ctx.entities.entities {
			label := fmt.tprint(e.entity)
			n, err := ecs.get_component(step.ecs_ctx, e.entity, name)
			if err == .NO_ERROR {
				label = fmt.tprintf("%s (%s)", n^, label)
			}
			if mu.button(step.mu_ctx, label) == {.SUBMIT} {
				state, ok := resources_get(step.resources, editor_state)
				if ok {
					state.selected_entity = e
				}
			}
		}

		mu.layout_end_column(step.mu_ctx)
		mu.end_window(step.mu_ctx)
	}
}


editor_resources_window_system :: proc(#by_ptr step: editor_step) {
	pad_left := i32(f32(rl.GetScreenWidth()) * SCENE_WINDOW_WIDTH_PERC)
	pad_top := i32(f32(rl.GetScreenHeight()) * CONTEXT_MENU_HEIGHT_PERC)
	resources_window_width := i32(f32(rl.GetScreenWidth()) * 0.6)
	resources_window_height := i32(f32(rl.GetScreenHeight()) * 0.2)
	if mu.begin_window(
		step.mu_ctx,
		"Resources",
		{
			pad_left,
			rl.GetScreenHeight() - resources_window_height,
			resources_window_width,
			resources_window_height,
		},
	) {
		mu.layout_begin_column(step.mu_ctx)
		mu.layout_row(step.mu_ctx, []i32{0})
		state, ok := resources_get(step.resources, editor_state)
		if !ok {
			mu.end_window(step.mu_ctx)
			return
		}

		for res_type, res_val in step.resources {
			label_txt := fmt.tprintf("%s", res_type)
			drawer, ok := state.type_drawers[res_type]
			if !ok {
				mu.header(step.mu_ctx, label_txt)
				continue
			} else {
				if mu.header(step.mu_ctx, label_txt, {.EXPANDED}) == {.ACTIVE} {
					drawer(step.mu_ctx, res_val)
				}
			}
		}
		mu.layout_end_column(step.mu_ctx)
		mu.end_window(step.mu_ctx)
	}
}

editor_inspector_window_system :: proc(#by_ptr step: editor_step) {
	pad_top := i32(f32(rl.GetScreenHeight()) * CONTEXT_MENU_HEIGHT_PERC)
	inspector_window_width := i32(f32(rl.GetScreenWidth()) * 0.2)
	inspector_window_height := i32(f32(rl.GetScreenHeight()) * 1.0) - pad_top
	if mu.begin_window(
		step.mu_ctx,
		"Inspector",
		{
			rl.GetScreenWidth() - inspector_window_width,
			pad_top,
			inspector_window_width,
			inspector_window_height,
		},
	) {
		mu.layout_begin_column(step.mu_ctx)
		mu.layout_row(step.mu_ctx, []i32{0})

		state, ok := resources_get(step.resources, editor_state)
		if ok && state.selected_entity.is_valid {
			{
				n, err := ecs.get_component(step.ecs_ctx, state.selected_entity.entity, name)
				if err == .NO_ERROR {
					if mu.header(step.mu_ctx, fmt.tprintf("%s", typeid_of(name)), {.EXPANDED}) ==
					   {.ACTIVE} {
						drawer, ok := state.type_drawers[name]
						if ok {
							drawer(step.mu_ctx, n)
						}
					}
				}
			}
			{
				transform, err := ecs.get_component(
					step.ecs_ctx,
					state.selected_entity.entity,
					rl.Transform,
				)
				if err == .NO_ERROR {
					if mu.header(
						   step.mu_ctx,
						   fmt.tprintf("%s", typeid_of(rl.Transform)),
						   {.EXPANDED},
					   ) ==
					   {.ACTIVE} {
						drawer, ok := state.type_drawers[rl.Transform]
						if ok {
							drawer(step.mu_ctx, transform)
						}
					}
				}
			}
		}

		mu.layout_end_column(step.mu_ctx)
		mu.end_window(step.mu_ctx)
	}
}
