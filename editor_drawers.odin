package tyr

import "core:math/linalg"

editor_drawers_plugin :: proc(app: ^app) {
	editor_register_drawer(&app.resources, int, editor_drawer_int)
	editor_register_drawer(&app.resources, i32, editor_drawer_i32)
	editor_register_drawer(&app.resources, f32, editor_drawer_f32)
	editor_register_drawer(&app.resources, color, editor_drawer_color)
	editor_register_drawer(&app.resources, clear_color, editor_drawer_color)
	editor_register_drawer(&app.resources, vec3, editor_drawer_vec3)
	editor_register_drawer(&app.resources, quat, editor_drawer_quat)
	editor_register_drawer(&app.resources, name, editor_drawer_name)
}

editor_drawer_int :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^int)obj
	val_i32 := i32(val^)
	ui_drag_int(ui, "##", &val_i32)
	val^ = int(val_i32)
}

editor_drawer_i32 :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^i32)obj
	ui_drag_int(ui, "##", val)
}

editor_drawer_f32 :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^f32)obj
	ui_drag_float(ui, "##", val)
}

editor_drawer_color :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^color)obj
	val_fp := [?]fp{fp(val.r) / 255.0, fp(val.g) / 255.0, fp(val.b) / 255.0, fp(val.a) / 255.0}
	ui_color_edit_4(ui, "##", &val_fp)
	val^ = color(
		{u8(val_fp.r * 255.0), u8(val_fp.g * 255.0), u8(val_fp.b * 255.0), u8(val_fp.a * 255.0)},
	)
}

editor_drawer_vec3 :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^vec3)obj
	val_fp := [?]fp{val.x, val.y, val.z}
	ui_drag_float3(ui, "##", &val_fp)
	val^ = val_fp
}

editor_drawer_quat :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^quat)obj

	x, y, z := linalg.euler_angles_xyz_from_quaternion(quaternion128(val^))
	euler_fp := [?]fp{x, y, z} * linalg.DEG_PER_RAD
	ui_drag_float3(ui, "##", &euler_fp)
	euler_fp = euler_fp * linalg.RAD_PER_DEG
	val^ = linalg.quaternion_from_euler_angles(euler_fp[0], euler_fp[1], euler_fp[2], .XYZ)
}

editor_drawer_name :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^name)obj
	val_str := string(val^)
	ui_input_text(ui, "##", &val_str)
	val^ = name(val_str)
}
