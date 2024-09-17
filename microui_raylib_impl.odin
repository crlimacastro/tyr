package tyr

import "core:fmt"
import "core:mem"
import "core:strings"
import ecs "odin-ecs"
import mu "vendor:microui"
import rl "vendor:raylib"


microui_raylib_mouse_buttons := [?]struct {
	raylib_button:  rl.MouseButton,
	microui_button: mu.Mouse,
}{{.LEFT, .LEFT}, {.RIGHT, .RIGHT}, {.MIDDLE, .MIDDLE}}

microui_raylib_keyboard_keys := [?]struct {
	raylib_key:  rl.KeyboardKey,
	microui_key: mu.Key,
} {
	{.LEFT_SHIFT, .SHIFT},
	{.RIGHT_SHIFT, .SHIFT},
	{.LEFT_CONTROL, .CTRL},
	{.RIGHT_CONTROL, .CTRL},
	{.LEFT_ALT, .ALT},
	{.RIGHT_ALT, .ALT},
	{.ENTER, .RETURN},
	{.KP_ENTER, .RETURN},
	{.BACKSPACE, .BACKSPACE},
}

microui_raylib_impl_state :: struct {
	ctx:             ^mu.Context,
	log_buf:         [1 << 16]byte,
	log_buf_len:     int,
	log_buf_updated: bool,
	atlas_texture:   rl.Texture2D,
}

microui_raylib_impl_step :: struct {
	using step: app_step,
	mu_ctx:     ^mu.Context,
}

microui_raylib_impl_plugin :: proc(app: ^app) {
	resources_set(&app.resources, microui_raylib_impl_state, microui_raylib_impl_state{})
	app_add_systems(app, init_step, microui_raylib_impl_init_system)
	app_add_systems(
		app,
		update_step,
		microui_raylib_impl_process_keyboard_key_system,
		microui_raylib_impl_process_mouse_button_system,
		microui_raylib_impl_process_mouse_move_system,
		microui_raylib_impl_process_scroll_system,
		microui_raylib_impl_process_text_system,
		microui_raylib_impl_update_system,
		microui_raylib_impl_process_commands_system,
	)
	app_add_systems(app, deinit_step, microui_raylib_impl_deinit_system)
}

microui_raylib_impl_init_system :: proc(#by_ptr step: init_step) {
	state := resources_get_or_make(step.resources, microui_raylib_impl_state)

	maybe_ctx, err := mem.alloc(size_of(mu.Context))
	if err != .None {
		panic(fmt.tprintf("failed to allocate microui context: %s", err))
	}
	ctx := cast(^mu.Context)maybe_ctx
	mu.init(ctx, proc(user_data: rawptr, text: string) -> (ok: bool) {
			rl.SetClipboardText(strings.clone_to_cstring(text, context.temp_allocator))
			return true
		}, proc(user_data: rawptr) -> (text: string, ok: bool) {
			return strings.clone_from_cstring(rl.GetClipboardText(), context.temp_allocator), true
		}, nil)
	ctx.text_width = mu.default_atlas_text_width
	ctx.text_height = mu.default_atlas_text_height
	state.ctx = ctx
	pixels := make([][4]u8, mu.DEFAULT_ATLAS_WIDTH * mu.DEFAULT_ATLAS_HEIGHT)
	// defer delete(pixels)
	for alpha, i in mu.default_atlas_alpha {
		pixels[i] = {0xff, 0xff, 0xff, alpha}
	}
	image := rl.Image {
		data    = raw_data(pixels),
		width   = mu.DEFAULT_ATLAS_WIDTH,
		height  = mu.DEFAULT_ATLAS_HEIGHT,
		mipmaps = 1,
		format  = .UNCOMPRESSED_R8G8B8A8,
	}
	state.atlas_texture = rl.LoadTextureFromImage(image)
}

microui_raylib_impl_update_system :: proc(#by_ptr step: update_step) {
	state, ok := resources_get(step.resources, microui_raylib_impl_state)
	if !ok {return}

	mu.begin(state.ctx)
	scheduler_dispatch(
		step.scheduler,
		microui_raylib_impl_step,
		microui_raylib_impl_step {
			resources = step.resources,
			scheduler = step.scheduler,
			mu_ctx = state.ctx,
			ecs_ctx = step.ecs_ctx,
		},
	)
	mu.end(state.ctx)
}

microui_raylib_impl_process_keyboard_key_system :: proc(#by_ptr step: update_step) {
	state, ok := resources_get(step.resources, microui_raylib_impl_state)
	if !ok {return}

	for key in microui_raylib_keyboard_keys {
		if rl.IsKeyPressed(key.raylib_key) {
			mu.input_key_down(state.ctx, key.microui_key)
		} else if rl.IsKeyReleased(key.raylib_key) {
			mu.input_key_up(state.ctx, key.microui_key)
		}
	}
}

microui_raylib_impl_process_mouse_button_system :: proc(#by_ptr step: update_step) {
	state, ok := resources_get(step.resources, microui_raylib_impl_state)
	if !ok {return}

	for button in microui_raylib_mouse_buttons {
		if rl.IsMouseButtonPressed(button.raylib_button) {
			mouse_pos := rl.GetMousePosition()
			mu.input_mouse_down(
				state.ctx,
				i32(mouse_pos.x),
				i32(mouse_pos.y),
				button.microui_button,
			)
		} else if rl.IsMouseButtonReleased(button.raylib_button) {
			mouse_pos := rl.GetMousePosition()
			mu.input_mouse_up(state.ctx, i32(mouse_pos.x), i32(mouse_pos.y), button.microui_button)
		}
	}
}

microui_raylib_impl_process_mouse_move_system :: proc(#by_ptr step: update_step) {
	state, ok := resources_get(step.resources, microui_raylib_impl_state)
	if !ok {return}

	mouse_pos := rl.GetMousePosition()
	x, y := i32(mouse_pos.x), i32(mouse_pos.y)
	if x == 0 && y == 0 {
		return
	}
	mu.input_mouse_move(state.ctx, x, y)
}

microui_raylib_impl_process_scroll_system :: proc(#by_ptr step: update_step) {
	state, ok := resources_get(step.resources, microui_raylib_impl_state)
	if !ok {return}

	scroll := rl.GetMouseWheelMoveV()
	x, y := i32(scroll.x), i32(scroll.y)
	if x == 0 && y == 0 {
		return
	}
	mu.input_scroll(state.ctx, x, y * -30)
}

microui_raylib_impl_process_text_system :: proc(#by_ptr step: update_step) {
	state, ok := resources_get(step.resources, microui_raylib_impl_state)
	if !ok {return}

	char := rl.GetCharPressed()
	for char != 0 {
		mu.input_text(state.ctx, fmt.tprint(char))
		char = rl.GetCharPressed()
	}
}

microui_raylib_impl_process_commands_system :: proc(#by_ptr step: update_step) {
	state, ok := resources_get(step.resources, microui_raylib_impl_state)
	if !ok {return}

	render_texture :: proc(
		state: ^microui_raylib_impl_state,
		rect: mu.Rect,
		pos: [2]i32,
		color: mu.Color,
	) {
		source := rl.Rectangle{f32(rect.x), f32(rect.y), f32(rect.w), f32(rect.h)}
		position := rl.Vector2{f32(pos.x), f32(pos.y)}

		rl.DrawTextureRec(state.atlas_texture, source, position, transmute(rl.Color)color)
	}

	command: ^mu.Command
	for variant in mu.next_command_iterator(state.ctx, &command) {
		switch cmd in variant {
		case ^mu.Command_Text:
			pos := [2]i32{cmd.pos.x, cmd.pos.y}
			for ch in cmd.str do if ch & 0xc0 != 0x80 {
				r := min(int(ch), 127)
				rect := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r]
				render_texture(state, rect, pos, cmd.color)
				pos.x += rect.w
			}
		case ^mu.Command_Rect:
			rl.DrawRectangle(
				cmd.rect.x,
				cmd.rect.y,
				cmd.rect.w,
				cmd.rect.h,
				transmute(rl.Color)cmd.color,
			)
		case ^mu.Command_Icon:
			rect := mu.default_atlas[cmd.id]
			x := cmd.rect.x + (cmd.rect.w - rect.w) / 2
			y := cmd.rect.y + (cmd.rect.h - rect.h) / 2
			render_texture(state, rect, {x, y}, cmd.color)
		case ^mu.Command_Clip:
			// noclip
		case ^mu.Command_Jump:
			unreachable()
		}
	}
}

microui_raylib_impl_deinit_system :: proc(#by_ptr step: deinit_step) {
	state, ok := resources_get(step.resources, microui_raylib_impl_state)
	if !ok {return}

	rl.UnloadTexture(state.atlas_texture)
}

microui_raylib_impl_write_log :: proc(resources: ^resources, str: string) {
	state, ok := resources_get(resources, microui_raylib_impl_state)
	if !ok {return}

	state.log_buf_len += copy(state.log_buf[state.log_buf_len:], str)
	state.log_buf_len += copy(state.log_buf[state.log_buf_len:], "\n")
	state.log_buf_updated = true
}

microui_raylib_impl_read_log :: proc(resources: ^resources) -> string {
	state, ok := resources_get(resources, microui_raylib_impl_state)
	if !ok {return ""}

	return string(state.log_buf[:state.log_buf_len])
}

microui_raylib_impl_reset_log :: proc(resources: ^resources) {
	state, ok := resources_get(resources, microui_raylib_impl_state)
	if !ok {return}

	state.log_buf_updated = true
	state.log_buf_len = 0
}
