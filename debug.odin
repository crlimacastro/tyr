package tyr

import "core:c"
import rl "vendor:raylib"

debug_quit_on_escape :: proc(app: ^app) {
    when !ODIN_DEBUG {
        return
    }
    if rl.IsKeyPressed(.ESCAPE) {
        app.is_running = false
    }
}

debug_draw_fps :: proc(pos_x, pos_y: int) {
    when !ODIN_DEBUG {
        return
    }
    rl.DrawFPS(c.int(pos_x), c.int(pos_y))
}
