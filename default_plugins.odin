package tyr

default_plugins_plugin :: proc(app: ^app) {
	app_add_plugins(app, input_plugin, rendering_plugin, ui_plugin)
}
