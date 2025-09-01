package tyr

input :: struct {
	data:                  rawptr,
	is_key_down:           proc(data: rawptr, value: keyboard_key) -> bool,
	is_key_pressed:        proc(data: rawptr, value: keyboard_key) -> bool,
	is_key_released:       proc(data: rawptr, value: keyboard_key) -> bool,
	is_mouse_down:         proc(data: rawptr, value: mouse_button) -> bool,
	is_mouse_pressed:      proc(data: rawptr, value: mouse_button) -> bool,
	is_mouse_released:     proc(data: rawptr, value: mouse_button) -> bool,
	get_mouse_position:    proc(data: rawptr) -> vec2,
	get_mouse_delta:       proc(data: rawptr) -> vec2,
	set_mouse_position:    proc(data: rawptr, value: vec2),
	get_mouse_wheel_delta: proc(data: rawptr) -> vec2,
}

input_action :: struct($t_value: typeid) {
	activators: [dynamic]keyboard_key,
	value:      $t_value,
	processors: [dynamic]proc(#by_ptr value: $t_value) -> $t_value,
}

input_is_key_down :: proc(input: ^input, value: keyboard_key) -> bool {
	return input.is_key_down(input.data, value)
}

input_is_key_up :: proc(input: ^input, value: keyboard_key) -> bool {
	return !input_is_key_down(input, value)
}

input_is_key_pressed :: proc(input: ^input, value: keyboard_key) -> bool {
	return input.is_key_pressed(input.data, value)
}

input_is_key_released :: proc(input: ^input, value: keyboard_key) -> bool {
	return input.is_key_released(input.data, value)
}

input_is_mouse_down :: proc(input: ^input, value: mouse_button) -> bool {
	return input.is_mouse_down(input.data, value)
}

input_is_mouse_up :: proc(input: ^input, value: mouse_button) -> bool {
	return !input_is_mouse_down(input, value)
}

input_is_mouse_pressed :: proc(input: ^input, value: mouse_button) -> bool {
	return input.is_mouse_pressed(input.data, value)
}

input_is_mouse_released :: proc(input: ^input, value: mouse_button) -> bool {
	return input.is_mouse_released(input.data, value)
}

input_get_mouse_position :: proc(input: ^input) -> vec2 {
	return input.get_mouse_position(input.data)
}

input_get_mouse_delta :: proc(input: ^input) -> vec2 {
	return input.get_mouse_delta(input.data)
}

input_set_mouse_position :: proc(input: ^input, value: vec2) {
	input.set_mouse_position(input.data, value)
}

input_get_mouse_wheel_delta :: proc(input: ^input) -> vec2 {
	return input.get_mouse_wheel_delta(input.data)
}

input_plugin :: proc(app: ^app) {
	app_add_systems(app, update_step, input_toggle_fullscreen_on_alt_enter_system)
}

input_toggle_fullscreen_on_alt_enter_system :: proc(#by_ptr step: update_step) {
	input, ok := resources_get(step.resources, input)
	if !ok {return}
	if input_is_key_down(input, .LEFT_ALT) && input_is_key_pressed(input, .ENTER) {
		window, ok := resources_get(step.resources, window)
		if !ok {return}
		window_toggle_fullscreen(window)
	}
}

input_quit_on_escape_system :: proc(#by_ptr step: update_step) {
	input, ok := resources_get(step.resources, input)
	if !ok {return}
	if input_is_key_pressed(input, .ESCAPE) {
		scheduler_dispatch(step.scheduler, app_quit, app_quit{step = step})
	}
}
