package tyr

window :: struct {
	data:      rawptr,
	set_title: proc(data: rawptr, value: string),
	should_close: proc(data: rawptr) -> bool,
	toggle_fullscreen: proc(data: rawptr),
}

window_set_title :: proc(window: ^window, value: string) {
	window.set_title(window.data, value)
}

window_should_close :: proc(window: ^window) -> bool {
	return window.should_close(window.data)
}

window_toggle_fullscreen :: proc(window: ^window) {
	window.toggle_fullscreen(window.data)
}

windowing_plugin :: proc(app: ^app) {
	app_add_plugins(app, raylib_plugin)
}
