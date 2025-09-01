package tyr

import "core:c"
import "core:strings"
import rl "vendor:raylib"
import "vendor:raylib/rlgl"

keyboard_key :: rl.KeyboardKey
mouse_button :: rl.MouseButton
texture :: rl.Texture
mesh :: rl.Mesh
camera_projection :: rl.CameraProjection

raylib_drawing_step :: struct {
	using step: app_step,
}

raylib_drawing_3d_step :: struct {
	using step: app_step,
}

raylib_window :: proc() -> window {
	return {data = {}, set_title = proc(data: rawptr, value: string) {
			value_cstr := strings.clone_to_cstring(value, context.temp_allocator)
			rl.SetWindowTitle(value_cstr)
		}, should_close = proc(data: rawptr) -> bool {
			return rl.WindowShouldClose()
		}, is_fullscreen = proc(data: rawptr) -> bool {
			return rl.IsWindowFullscreen()
		}, set_fullscreen = proc(data: rawptr, value: bool) {
			if rl.IsWindowFullscreen() != value {
				rl.ToggleFullscreen()
			}
		}, is_maximized = proc(data: rawptr) -> bool {
			return rl.IsWindowMaximized()
		}, maximize = proc(data: rawptr) {
			rl.MaximizeWindow()
		}, get_position = proc(data: rawptr) -> vec2 {
			return rl.GetWindowPosition()
		}, get_size = proc(data: rawptr) -> vec2 {
			return vec2{fp(rl.GetScreenWidth()), fp(rl.GetScreenHeight())}
		}, set_position = proc(data: rawptr, value: vec2) {
			rl.SetWindowPosition(c.int(value.x), c.int(value.y))
		}, set_size = proc(data: rawptr, value: vec2) {
			rl.SetWindowSize(c.int(value.x), c.int(value.y))
		}}
}

raylib_input :: proc() -> input {
	return {data = {}, is_key_down = proc(data: rawptr, key: keyboard_key) -> bool {
			return rl.IsKeyDown(key)
		}, is_key_pressed = proc(data: rawptr, key: keyboard_key) -> bool {
			return rl.IsKeyPressed(key)
		}, is_key_released = proc(data: rawptr, key: keyboard_key) -> bool {
			return rl.IsKeyReleased(key)
		}, is_mouse_down = proc(data: rawptr, button: mouse_button) -> bool {
			return rl.IsMouseButtonDown(button)
		}, is_mouse_pressed = proc(data: rawptr, button: mouse_button) -> bool {
			return rl.IsMouseButtonPressed(button)
		}, is_mouse_released = proc(data: rawptr, button: mouse_button) -> bool {
			return !rl.IsMouseButtonPressed(button)
		}, get_mouse_position = proc(data: rawptr) -> vec2 {
			return rl.GetMousePosition()
		}, get_mouse_delta = proc(data: rawptr) -> vec2 {
			return rl.GetMouseDelta()
		}, set_mouse_position = proc(data: rawptr, value: vec2) {
			rl.SetMousePosition(c.int(value.x), c.int(value.y))
		}, get_mouse_wheel_delta = proc(data: rawptr) -> vec2 {
			return vec2(rl.GetMouseWheelMoveV())
		}}
}

raylib_renderer :: proc() -> renderer {
	return {data = {}, load_texture = proc(data: rawptr, filename: string) -> texture {
			filename_cstr := strings.clone_to_cstring(filename, context.temp_allocator)
			rl_texture := rl.LoadTexture(filename_cstr)
			return rl_texture
		}, render_sprite = proc(
			data: rawptr,
			sprite: ^sprite,
			position: vec2,
			rotation: fp = 0,
			scale: vec2 = {1, 1},
			tint: color,
			flip: [2]bool = {false, false},
		) {
			rl_texture := sprite.texture
			rlgl.PushMatrix()
			rlgl.Translatef(position.x, position.y, 0)
			rlgl.Rotatef(rotation, 0, 0, 1)
			rlgl.Scalef(scale.x, scale.y, 1)
			src_rect := rl.Rectangle {
				f32(sprite.source.x),
				f32(sprite.source.y),
				f32(sprite.source.width) * (flip.x ? -1 : 1),
				f32(sprite.source.height) * (flip.y ? -1 : 1),
			}
			dst_rect := rl.Rectangle{0, 0, f32(sprite.texture.width), f32(sprite.texture.height)}
			rl.DrawTexturePro(
				rl_texture,
				src_rect,
				dst_rect,
				rl.Vector2{fp(sprite.texture.width) / 2, fp(sprite.texture.height) / 2},
				0,
				transmute(rl.Color)(tint),
			)
			rlgl.PopMatrix()
		}, render_mesh = proc(
			data: rawptr,
			mesh: ^mesh,
			position: vec3 = {},
			rotation: vec3 = {},
			scale: vec3 = {1, 1, 1},
		) {
			material := rl.LoadMaterialDefault()
			m :=
				rl.MatrixTranslate(position.x, position.y, position.z) *
				rl.MatrixRotateXYZ(rotation) *
				rl.MatrixScale(scale.x, scale.y, scale.z)
			rl.DrawMesh(mesh^, material, m)
		}}
}

raylib_plugin :: proc(app: ^app) {
	rl.SetTraceLogLevel(.WARNING)
	config_flags: rl.ConfigFlags = {.WINDOW_RESIZABLE}
	rl.SetConfigFlags(config_flags)
	rl.InitWindow(1920, 1080, "")
	rl.SetExitKey(.KEY_NULL)

	app_set_resource(app, raylib_input())
	app_set_resource(app, raylib_window())
	app_set_resource(app, raylib_renderer())
	app_add_systems(app, update_step, raylib_drawing_step_system)
	app_add_systems(app, raylib_drawing_step, raylib_drawing_3d_step_system)
	app_add_systems(app, deinit_step, raylib_deinit_system)
}

raylib_drawing_step_system :: proc(#by_ptr step: update_step) {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	clear_col := black
	maybe_clear_color, ok := resources_get(step.resources, clear_color)
	if ok {
		clear_col = color(maybe_clear_color^)
	}
	rl.ClearBackground(rl.Color(clear_col))

	scheduler_dispatch(step.scheduler, raylib_drawing_step, raylib_drawing_step{step = step})
}

raylib_drawing_3d_step_system :: proc(#by_ptr step: raylib_drawing_step) {
	main_camera, ok := resources_get(step.resources, main_camera3d)
	if !ok {
		return
	}
	camera, okk := ecs_get_component(step.ecs_ctx, main_camera.entity, camera3d)
	if !okk {
		return
	}
	position := vec3{0, 0, 0}
	target := vec3{0, 0, 1}
	up := vec3{0, 1, 0}
	if cam_transform, okkk := ecs_get_component(step.ecs_ctx, main_camera.entity, transform3);
	   okkk {
		position = cam_transform.translation
		target = cam_transform.translation + {0, 0, 1}
		up = {0, 1, 0}
	}

	projection := camera.projection

	rl_camera := rl.Camera3D {
		position   = position,
		target     = target,
		up         = up,
		fovy       = camera.fovy,
		projection = projection,
	}

	rl.BeginMode3D(rl_camera)
	defer rl.EndMode3D()

	scheduler_dispatch(step.scheduler, raylib_drawing_3d_step, raylib_drawing_3d_step{step = step})
}

raylib_deinit_system :: proc(#by_ptr step: deinit_step) {
	rl.CloseWindow()
}
