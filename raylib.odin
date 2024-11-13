package tyr

import "core:c"
import "core:strings"
import rl "vendor:raylib"
import "vendor:raylib/rlgl"

input_keyboard_key_to_rl_keyboard_key := map[keyboard_key]rl.KeyboardKey {
	.key_null      = .KEY_NULL,
	.apostrophe    = .APOSTROPHE,
	.comma         = .COMMA,
	.minus         = .MINUS,
	.period        = .PERIOD,
	.slash         = .SLASH,
	.zero          = .ZERO,
	.one           = .ONE,
	.two           = .TWO,
	.three         = .THREE,
	.four          = .FOUR,
	.five          = .FIVE,
	.six           = .SIX,
	.seven         = .SEVEN,
	.eight         = .EIGHT,
	.nine          = .NINE,
	.semicolon     = .SEMICOLON,
	.equal         = .EQUAL,
	.a             = .A,
	.b             = .B,
	.c             = .C,
	.d             = .D,
	.e             = .E,
	.f             = .F,
	.g             = .G,
	.h             = .H,
	.i             = .I,
	.j             = .J,
	.k             = .K,
	.l             = .L,
	.m             = .M,
	.n             = .N,
	.o             = .O,
	.p             = .P,
	.q             = .Q,
	.r             = .R,
	.s             = .S,
	.t             = .T,
	.u             = .U,
	.v             = .V,
	.w             = .W,
	.x             = .X,
	.y             = .Y,
	.z             = .Z,
	.left_bracket  = .LEFT_BRACKET,
	.backslash     = .BACKSLASH,
	.right_bracket = .RIGHT_BRACKET,
	.grave         = .GRAVE,
	.space         = .SPACE,
	.escape        = .ESCAPE,
	.enter         = .ENTER,
	.tab           = .TAB,
	.backspace     = .BACKSPACE,
	.insert        = .INSERT,
	.delete        = .DELETE,
	.right         = .RIGHT,
	.left          = .LEFT,
	.down          = .DOWN,
	.up            = .UP,
	.page_up       = .PAGE_UP,
	.page_down     = .PAGE_DOWN,
	.home          = .HOME,
	.end           = .END,
	.caps_lock     = .CAPS_LOCK,
	.scroll_lock   = .SCROLL_LOCK,
	.num_lock      = .NUM_LOCK,
	.print_screen  = .PRINT_SCREEN,
	.pause         = .PAUSE,
	.f1            = .F1,
	.f2            = .F2,
	.f3            = .F3,
	.f4            = .F4,
	.f5            = .F5,
	.f6            = .F6,
	.f7            = .F7,
	.f8            = .F8,
	.f9            = .F9,
	.f10           = .F10,
	.f11           = .F11,
	.f12           = .F12,
	.left_shift    = .LEFT_SHIFT,
	.left_control  = .LEFT_CONTROL,
	.left_alt      = .LEFT_ALT,
	.left_super    = .LEFT_SUPER,
	.right_shift   = .RIGHT_SHIFT,
	.right_control = .RIGHT_CONTROL,
	.right_alt     = .RIGHT_ALT,
	.right_super   = .RIGHT_SUPER,
	.kb_menu       = .KB_MENU,
	.kp_0          = .KP_0,
	.kp_1          = .KP_1,
	.kp_2          = .KP_2,
	.kp_3          = .KP_3,
	.kp_4          = .KP_4,
	.kp_5          = .KP_5,
	.kp_6          = .KP_6,
	.kp_7          = .KP_7,
	.kp_8          = .KP_8,
	.kp_9          = .KP_9,
	.kp_decimal    = .KP_DECIMAL,
	.kp_divide     = .KP_DIVIDE,
	.kp_multiply   = .KP_MULTIPLY,
	.kp_subtract   = .KP_SUBTRACT,
	.kp_add        = .KP_ADD,
	.kp_enter      = .KP_ENTER,
	.kp_equal      = .KP_EQUAL,
	.back          = .BACK,
	.menu          = .MENU,
	.volume_up     = .VOLUME_UP,
	.volume_down   = .VOLUME_DOWN,
}

input_mouse_button_to_rl_mouse_button := map[mouse_button]rl.MouseButton {
	.left    = .LEFT,
	.right   = .RIGHT,
	.middle  = .MIDDLE,
	.side    = .SIDE,
	.extra   = .EXTRA,
	.forward = .FORWARD,
	.back    = .BACK,
}

rendering_pixel_format_to_rl_pixel_format := map[pixel_format]rl.PixelFormat {
	.unknown                   = .UNKNOWN,
	.uncompressed_grayscale    = .UNCOMPRESSED_GRAYSCALE,
	.uncompressed_gray_alpha   = .UNCOMPRESSED_GRAY_ALPHA,
	.uncompressed_r5g6b5       = .UNCOMPRESSED_R5G6B5,
	.uncompressed_r8g8b8       = .UNCOMPRESSED_R8G8B8,
	.uncompressed_r5g5b5a1     = .UNCOMPRESSED_R5G5B5A1,
	.uncompressed_r4g4b4a4     = .UNCOMPRESSED_R4G4B4A4,
	.uncompressed_r8g8b8a8     = .UNCOMPRESSED_R8G8B8A8,
	.uncompressed_r32          = .UNCOMPRESSED_R32,
	.uncompressed_r32g32b32    = .UNCOMPRESSED_R32G32B32,
	.uncompressed_r32g32b32a32 = .UNCOMPRESSED_R32G32B32A32,
	.uncompressed_r16          = .UNCOMPRESSED_R16,
	.uncompressed_r16g16b16    = .UNCOMPRESSED_R16G16B16,
	.uncompressed_r16g16b16a16 = .UNCOMPRESSED_R16G16B16A16,
	.compressed_dxt1_rgb       = .COMPRESSED_DXT1_RGB,
	.compressed_dxt1_rgba      = .COMPRESSED_DXT1_RGBA,
	.compressed_dxt3_rgba      = .COMPRESSED_DXT3_RGBA,
	.compressed_dxt5_rgba      = .COMPRESSED_DXT5_RGBA,
	.compressed_etc1_rgb       = .COMPRESSED_ETC1_RGB,
	.compressed_etc2_rgb       = .COMPRESSED_ETC2_RGB,
	.compressed_etc2_eac_rgba  = .COMPRESSED_ETC2_EAC_RGBA,
	.compressed_pvrt_rgb       = .COMPRESSED_PVRT_RGB,
	.compressed_pvrt_rgba      = .COMPRESSED_PVRT_RGBA,
	.compressed_astc_4x4_rgba  = .COMPRESSED_ASTC_4x4_RGBA,
	.compressed_astc_8x8_rgba  = .COMPRESSED_ASTC_8x8_RGBA,
}

rl_pixel_format_to_rendering_pixel_format := map[rl.PixelFormat]pixel_format {
	.UNKNOWN                   = .unknown,
	.UNCOMPRESSED_GRAYSCALE    = .uncompressed_grayscale,
	.UNCOMPRESSED_GRAY_ALPHA   = .uncompressed_gray_alpha,
	.UNCOMPRESSED_R5G6B5       = .uncompressed_r5g6b5,
	.UNCOMPRESSED_R8G8B8       = .uncompressed_r8g8b8,
	.UNCOMPRESSED_R5G5B5A1     = .uncompressed_r5g5b5a1,
	.UNCOMPRESSED_R4G4B4A4     = .uncompressed_r4g4b4a4,
	.UNCOMPRESSED_R8G8B8A8     = .uncompressed_r8g8b8a8,
	.UNCOMPRESSED_R32          = .uncompressed_r32,
	.UNCOMPRESSED_R32G32B32    = .uncompressed_r32g32b32,
	.UNCOMPRESSED_R32G32B32A32 = .uncompressed_r32g32b32a32,
	.UNCOMPRESSED_R16          = .uncompressed_r16,
	.UNCOMPRESSED_R16G16B16    = .uncompressed_r16g16b16,
	.UNCOMPRESSED_R16G16B16A16 = .uncompressed_r16g16b16a16,
	.COMPRESSED_DXT1_RGB       = .compressed_dxt1_rgb,
	.COMPRESSED_DXT1_RGBA      = .compressed_dxt1_rgba,
	.COMPRESSED_DXT3_RGBA      = .compressed_dxt3_rgba,
	.COMPRESSED_DXT5_RGBA      = .compressed_dxt5_rgba,
	.COMPRESSED_ETC1_RGB       = .compressed_etc1_rgb,
	.COMPRESSED_ETC2_RGB       = .compressed_etc2_rgb,
	.COMPRESSED_ETC2_EAC_RGBA  = .compressed_etc2_eac_rgba,
	.COMPRESSED_PVRT_RGB       = .compressed_pvrt_rgb,
	.COMPRESSED_PVRT_RGBA      = .compressed_pvrt_rgba,
	.COMPRESSED_ASTC_4x4_RGBA  = .compressed_astc_4x4_rgba,
	.COMPRESSED_ASTC_8x8_RGBA  = .compressed_astc_8x8_rgba,
}

rendering_texture_to_rl_texture :: proc(#by_ptr texture: texture) -> rl.Texture2D {
	return rl.Texture2D {
		id = c.uint(texture.id),
		width = c.int(texture.width),
		height = c.int(texture.height),
		mipmaps = c.int(texture.mipmaps),
		format = rendering_pixel_format_to_rl_pixel_format[texture.format],
	}
}

rl_texture_to_rendering_texture :: proc(rl_texture: rl.Texture2D) -> texture {
	return {
		id = uint(rl_texture.id),
		width = int(rl_texture.width),
		height = int(rl_texture.height),
		mipmaps = int(rl_texture.mipmaps),
		format = rl_pixel_format_to_rendering_pixel_format[rl_texture.format],
	}
}

raylib_update_step :: struct {
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
		},
		is_maximized = proc(data: rawptr) -> bool {
			return rl.IsWindowMaximized()
		},
		maximize = proc(data: rawptr) {
			rl.MaximizeWindow()
		},
		get_position = proc(data: rawptr) -> vec2 {
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
			return rl.IsKeyDown(input_keyboard_key_to_rl_keyboard_key[key])
		}, is_key_pressed = proc(data: rawptr, key: keyboard_key) -> bool {
			return rl.IsKeyPressed(input_keyboard_key_to_rl_keyboard_key[key])
		}, is_key_released = proc(data: rawptr, key: keyboard_key) -> bool {
			return rl.IsKeyReleased(input_keyboard_key_to_rl_keyboard_key[key])
		}, is_mouse_down = proc(data: rawptr, button: mouse_button) -> bool {
			return rl.IsMouseButtonDown(input_mouse_button_to_rl_mouse_button[button])
		}, is_mouse_pressed = proc(data: rawptr, button: mouse_button) -> bool {
			return rl.IsMouseButtonPressed(input_mouse_button_to_rl_mouse_button[button])
		}, is_mouse_released = proc(data: rawptr, button: mouse_button) -> bool {
			return !rl.IsMouseButtonPressed(input_mouse_button_to_rl_mouse_button[button])
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
			return rl_texture_to_rendering_texture(rl_texture)
		}, render_sprite = proc(
			data: rawptr,
			sprite: ^sprite,
			position: vec2,
			rotation: fp = 0,
			scale: vec2 = {1, 1},
			tint: color,
			flip: [2]bool = { false, false },
		) {
			rl_texture := rendering_texture_to_rl_texture(sprite.texture)
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
	app_add_systems(app, update_step, raylib_update_system)
	app_add_systems(app, deinit_step, raylib_deinit_system)
}

raylib_update_system :: proc(#by_ptr step: update_step) {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	clear_col := black
	maybe_clear_color, ok := resources_get(step.resources, clear_color)
	if ok {
		clear_col = color(maybe_clear_color^)
	}
	rl.ClearBackground(rl.Color(clear_col))

	scheduler_dispatch(step.scheduler, raylib_update_step, raylib_update_step{step = step})
}

raylib_deinit_system :: proc(#by_ptr step: deinit_step) {
	rl.CloseWindow()
}
