package tyr

import rl "vendor:raylib"

input_plugin :: proc(app: ^app) {
    app_add_systems(app, update_step, toggle_fullscreen_on_alt_enter)
}

toggle_fullscreen_on_alt_enter :: proc(#by_ptr step: update_step) {
    if rl.IsKeyDown(.LEFT_ALT) && rl.IsKeyPressed(.ENTER) {
        rl.ToggleFullscreen()
    }
}

quit_on_escape :: proc(#by_ptr step: update_step) {
    if rl.IsKeyPressed(.ESCAPE) {
        scheduler_dispatch(step.scheduler, app_quit, app_quit{})
    }
}