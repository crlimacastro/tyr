package tyr

import "core:encoding/json"
import "core:fmt"
import "core:os"

window :: struct {
	data:           rawptr,
	set_title:      proc(data: rawptr, value: string),
	should_close:   proc(data: rawptr) -> bool,
	is_fullscreen:  proc(data: rawptr) -> bool,
	set_fullscreen: proc(data: rawptr, value: bool),
	get_position:   proc(data: rawptr) -> vec2,
	get_size:       proc(data: rawptr) -> vec2,
	set_position:   proc(data: rawptr, value: vec2),
	set_size:       proc(data: rawptr, value: vec2),
}

windowing_prefs :: struct {
	position:      vec2,
	size:          vec2,
	is_fullscreen: bool,
}

WINDOWING_PREFS_PATH :: PREFS_PATH + "/tyr_windowing_prefs.json"

window_set_title :: proc(window: ^window, value: string) {
	window.set_title(window.data, value)
}

window_should_close :: proc(window: ^window) -> bool {
	return window.should_close(window.data)
}

window_is_fullscreen :: proc(window: ^window) -> bool {
	return window.is_fullscreen(window.data)
}

window_set_fullscreen :: proc(window: ^window, value: bool) {
	window.set_fullscreen(window.data, value)
}

window_toggle_fullscreen :: proc(window: ^window) {
	if window_is_fullscreen(window) {
		window_set_fullscreen(window, false)
	} else {
		window_set_fullscreen(window, true)
	}
}

window_get_position :: proc(window: ^window) -> vec2 {
	return window.get_position(window.data)
}

window_get_size :: proc(window: ^window) -> vec2 {
	return window.get_size(window.data)
}

window_set_position :: proc(window: ^window, value: vec2) {
	window.set_position(window.data, value)
}

window_set_size :: proc(window: ^window, value: vec2) {
	window.set_size(window.data, value)
}

windowing_plugin :: proc(app: ^app) {
	app_add_plugins(app, raylib_plugin)
	app_add_systems(app, start_step, windowing_load_prefs_system)
	app_add_systems(app, stop_step, windowing_save_prefs_system)
}

windowing_load_prefs_system :: proc(#by_ptr step: start_step) {
	windowing_load_prefs(step.resources)
}

windowing_save_prefs_system :: proc(#by_ptr step: stop_step) {
	windowing_save_prefs(step.resources)
}

windowing_load_prefs :: proc(resources: ^resources) {
	if !os.exists(WINDOWING_PREFS_PATH) {return}
	file, file_err := os.open(WINDOWING_PREFS_PATH, os.O_RDONLY)
	if file_err != nil {
		panic(fmt.tprintf("%s", file_err))
	}
	defer os.close(file)
	data := []byte{}
	prefs_json_data, file_ok := os.read_entire_file(file)
	if !file_ok {
		panic(fmt.tprintf("error reading file: %s", WINDOWING_PREFS_PATH))
	}
	prefs := windowing_prefs{}
	json_err := json.unmarshal(prefs_json_data, &prefs)
	if json_err != nil {
		panic(fmt.tprintf("%s", json_err))
	}
	window, ok := resources_get(resources, window)
	if !ok {return}
	window_set_position(window, prefs.position)
	window_set_size(window, prefs.size)
	window_set_fullscreen(window, prefs.is_fullscreen)
}

windowing_save_prefs :: proc(resources: ^resources) {
	window, ok := resources_get(resources, window)
	if !ok {return}
	prefs := windowing_prefs {
		position      = window_get_position(window),
		size          = window_get_size(window),
		is_fullscreen = window_is_fullscreen(window),
	}
	prefs_json_data, json_err := json.marshal(prefs)
	if json_err != nil {
		panic(fmt.tprintf("%s", json_err))
	}
	create_prefs_dir()
	file, file_err := os.open(WINDOWING_PREFS_PATH, os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
	if file_err != nil {
		panic(fmt.tprintf("%s", file_err))
	}
	defer os.close(file)
	_, write_err := os.write(file, prefs_json_data)
	if write_err != nil {
		panic(fmt.tprintf("%s", write_err))
	}
}
