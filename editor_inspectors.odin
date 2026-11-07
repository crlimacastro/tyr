package tyr

import "core:reflect"
import "core:math"
import "core:math/linalg"

editor_inspectors_plugin :: proc(app: ^app) {
	editor_state_register_inspector(&app.resources, color, editor_inspector_color)
	editor_state_register_inspector(&app.resources, clear_color, editor_inspector_color)
	editor_state_register_inspector(&app.resources, vec2, editor_inspector_vec2)
	editor_state_register_inspector(&app.resources, vec3, editor_inspector_vec3)
}

editor_inspector_color :: proc(ui: ^ui, ptr: rawptr, info: ^reflect.Type_Info) {
	val := cast(^color)ptr
	val_fp := [?]fp{fp(val.r) / 255.0, fp(val.g) / 255.0, fp(val.b) / 255.0, fp(val.a) / 255.0}
	ui_color_edit_4(ui, "##", &val_fp)
	val^ = color(
		{u8(val_fp.r * 255.0), u8(val_fp.g * 255.0), u8(val_fp.b * 255.0), u8(val_fp.a * 255.0)},
	)
}

editor_inspector_vec2 :: proc(ui: ^ui, ptr: rawptr, info: ^reflect.Type_Info) {
	val := cast(^vec2)ptr
	val_fp := [?]fp{val.x, val.y}
	ui_drag_float2(ui, "##", &val_fp)
	val^ = val_fp
}

editor_inspector_vec3 :: proc(ui: ^ui, ptr: rawptr, info: ^reflect.Type_Info) {
	val := cast(^vec3)ptr
	val_fp := [?]fp{val.x, val.y, val.z}
	ui_drag_float3(ui, "##", &val_fp)
	val^ = val_fp
}
