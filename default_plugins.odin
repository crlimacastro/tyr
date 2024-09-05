package tyr

default_plugins :: proc(app: ^app) {
	app_add_plugins(app, input_plugin, rendering_plugin)
}
