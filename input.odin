package tyr

keyboard_key :: enum {
	key_null      = 0,
	apostrophe    = 39,
	comma         = 44,
	minus         = 45,
	period        = 46,
	slash         = 47,
	zero          = 48,
	one           = 49,
	two           = 50,
	three         = 51,
	four          = 52,
	five          = 53,
	six           = 54,
	seven         = 55,
	eight         = 56,
	nine          = 57,
	semicolon     = 59,
	equal         = 61,
	a             = 65,
	b             = 66,
	c             = 67,
	d             = 68,
	e             = 69,
	f             = 70,
	g             = 71,
	h             = 72,
	i             = 73,
	j             = 74,
	k             = 75,
	l             = 76,
	m             = 77,
	n             = 78,
	o             = 79,
	p             = 80,
	q             = 81,
	r             = 82,
	s             = 83,
	t             = 84,
	u             = 85,
	v             = 86,
	w             = 87,
	x             = 88,
	y             = 89,
	z             = 90,
	left_bracket  = 91,
	backslash     = 92,
	right_bracket = 93,
	grave         = 96,
	space         = 32,
	escape        = 256,
	enter         = 257,
	tab           = 258,
	backspace     = 259,
	insert        = 260,
	delete        = 261,
	right         = 262,
	left          = 263,
	down          = 264,
	up            = 265,
	page_up       = 266,
	page_down     = 267,
	home          = 268,
	end           = 269,
	caps_lock     = 280,
	scroll_lock   = 281,
	num_lock      = 282,
	print_screen  = 283,
	pause         = 284,
	f1            = 290,
	f2            = 291,
	f3            = 292,
	f4            = 293,
	f5            = 294,
	f6            = 295,
	f7            = 296,
	f8            = 297,
	f9            = 298,
	f10           = 299,
	f11           = 300,
	f12           = 301,
	left_shift    = 340,
	left_control  = 341,
	left_alt      = 342,
	left_super    = 343,
	right_shift   = 344,
	right_control = 345,
	right_alt     = 346,
	right_super   = 347,
	kb_menu       = 348,
	kp_0          = 320,
	kp_1          = 321,
	kp_2          = 322,
	kp_3          = 323,
	kp_4          = 324,
	kp_5          = 325,
	kp_6          = 326,
	kp_7          = 327,
	kp_8          = 328,
	kp_9          = 329,
	kp_decimal    = 330,
	kp_divide     = 331,
	kp_multiply   = 332,
	kp_subtract   = 333,
	kp_add        = 334,
	kp_enter      = 335,
	kp_equal      = 336,
	back          = 4,
	menu          = 82,
	volume_up     = 24,
	volume_down   = 25,
}

mouse_button :: enum {
	left    = 0, // mouse button left
	right   = 1, // mouse button right
	middle  = 2, // mouse button middle (pressed wheel)
	side    = 3, // mouse button side (advanced mouse device)
	extra   = 4, // mouse button extra (advanced mouse device)
	forward = 5, // mouse button fordward (advanced mouse device)
	back    = 6, // mouse button back (advanced mouse device)
}

input :: struct {
	data:           rawptr,
	is_key_down:    proc(data: rawptr, value: keyboard_key) -> bool,
	is_key_pressed: proc(data: rawptr, value: keyboard_key) -> bool,
	is_key_released: proc(data: rawptr, value: keyboard_key) -> bool,
	is_mouse_down:  proc(data: rawptr, value: mouse_button) -> bool,
	is_mouse_pressed: proc(data: rawptr, value: mouse_button) -> bool,
	is_mouse_released: proc(data: rawptr, value: mouse_button) -> bool,
	get_mouse_position: proc(data: rawptr) -> vec2,
	get_mouse_delta: proc(data: rawptr) -> vec2,
	set_mouse_position: proc(data: rawptr, value: vec2),
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
	if input_is_key_down(input, .left_alt) && input_is_key_pressed(input, .enter) {
		window, ok := resources_get(step.resources, window)
		if !ok {return}
		window_toggle_fullscreen(window)
	}
}

input_quit_on_escape_system :: proc(#by_ptr step: update_step) {
	input, ok := resources_get(step.resources, input)
	if !ok {return}
	if input_is_key_pressed(input, .escape) {
		scheduler_dispatch(step.scheduler, app_quit, app_quit{step = step})
	}
}
