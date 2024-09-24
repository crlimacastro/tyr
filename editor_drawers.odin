package tyr

import "core:fmt"
import rl "vendor:raylib"

editor_drawers_plugin :: proc(app: ^app) {
	editor_register_drawer(&app.resources, fp, editor_drawer_fp)
	editor_register_drawer(&app.resources, color, editor_drawer_color)
	editor_register_drawer(&app.resources, clear_color, editor_drawer_color)
	editor_register_drawer(&app.resources, vec3, editor_drawer_vec3)
	editor_register_drawer(&app.resources, quat, editor_drawer_quat)
	editor_register_drawer(&app.resources, name, editor_drawer_name)
}

editor_drawer_fp :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^fp)obj
	ui_drag_float(ui, "##", val)
}

editor_drawer_color :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^color)obj
	val_fp := [?]fp {
		fp(val.r) / 255.0,
		fp(val.g) / 255.0,
		fp(val.b) / 255.0,
		fp(val.a) / 255.0,
	}
	ui_color_edit_4(ui, "##", &val_fp)
	val^ = color(
		{
			u8(val_fp.r * 255.0),
			u8(val_fp.g * 255.0),
			u8(val_fp.b * 255.0),
			u8(val_fp.a * 255.0),
		},
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
	val_rl_quat := rl.Quaternion(val^)
	euler := rl.QuaternionToEuler(val_rl_quat)
	euler_fp := euler.xyz
	ui_drag_float3(ui, "##", &euler_fp)
	quat_rl := rl.QuaternionFromEuler(euler.z, euler.y, euler.x)
	val^ = quat(quat_rl)
}

editor_drawer_name :: proc(ui: ^ui, obj: rawptr) {
	val := cast(^name)obj
	val_str := string(val^)
	ui_input_text(ui, "##", &val_str)
	val^ = name(val_str)
}
