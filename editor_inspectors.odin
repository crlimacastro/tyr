package tyr

import "core:math"
import "core:math/linalg"

editor_inspectors_plugin :: proc(app: ^app) {
	editor_state_register_inspector(&app.resources, int, editor_inspector_int)
	editor_state_register_inspector(&app.resources, i32, editor_inspector_i32)
	editor_state_register_inspector(&app.resources, uint, editor_inspector_uint)
	editor_state_register_inspector(&app.resources, u32, editor_inspector_u32)
	editor_state_register_inspector(&app.resources, f32, editor_inspector_f32)
	editor_state_register_inspector(&app.resources, string, editor_inspector_string)
	editor_state_register_inspector(&app.resources, bool, editor_inspector_bool)
	editor_state_register_inspector(&app.resources, color, editor_inspector_color)
	editor_state_register_inspector(&app.resources, clear_color, editor_inspector_color)
	editor_state_register_inspector(&app.resources, vec2, editor_inspector_vec2)
	editor_state_register_inspector(&app.resources, vec3, editor_inspector_vec3)
	editor_state_register_inspector(&app.resources, quat, editor_inspector_quat)
}

editor_inspector_int :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^int)obj
	val_i32 := i32(val^)
	ui_drag_int(ui, "##", &val_i32)
	val^ = int(val_i32)
}

editor_inspector_i32 :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^i32)obj
	ui_drag_int(ui, "##", val)
}

editor_inspector_uint :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^uint)obj
	val_u32 := u32(val^)
	ui_drag_uint(ui, "##", &val_u32)
	val^ = uint(val_u32)
}

editor_inspector_u32 :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^u32)obj
	ui_drag_uint(ui, "##", val)
}


editor_inspector_f32 :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^f32)obj
	ui_drag_float(ui, "##", val)
}

editor_inspector_color :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^color)obj
	val_fp := [?]fp{fp(val.r) / 255.0, fp(val.g) / 255.0, fp(val.b) / 255.0, fp(val.a) / 255.0}
	ui_color_edit_4(ui, "##", &val_fp)
	val^ = color(
		{u8(val_fp.r * 255.0), u8(val_fp.g * 255.0), u8(val_fp.b * 255.0), u8(val_fp.a * 255.0)},
	)
}

editor_inspector_vec2 :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^vec2)obj
	val_fp := [?]fp{val.x, val.y}
	ui_drag_float2(ui, "##", &val_fp)
	val^ = val_fp
}

editor_inspector_vec3 :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^vec3)obj
	val_fp := [?]fp{val.x, val.y, val.z}
	ui_drag_float3(ui, "##", &val_fp)
	val^ = val_fp
}

editor_inspector_quat :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^quat)obj

	x, y, z := linalg.euler_angles_xyz_from_quaternion(val^)
	euler_fp := [?]fp{x, y, z} * linalg.DEG_PER_RAD
	ui_drag_float3(ui, "##", &euler_fp)
	euler_fp = euler_fp * linalg.RAD_PER_DEG
	dst := linalg.quaternion_from_euler_angles(euler_fp.x, euler_fp.y, euler_fp.z, .XYZ)
	val^ = dst
}

editor_inspector_string :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^string)obj
	ui_input_text(ui, "##", val)
}

editor_inspector_bool :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^bool)obj
	ui_checkbox(ui, "##", val)
}
