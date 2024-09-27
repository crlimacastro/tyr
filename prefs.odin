package tyr

import "core:os"
import "core:fmt"

PREFS_PATH :: ".tyr"

create_prefs_dir :: proc() {
	if os.exists(PREFS_PATH) {return}
	err := os.make_directory(PREFS_PATH)
	// if err != .None {
	// 	panic(fmt.tprintf("failed to create prefs dir: %s", err))
	// }
}
