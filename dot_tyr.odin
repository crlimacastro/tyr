// for engine settings & caches
package tyr

import "core:os"
import "core:fmt"

DOT_TYR_PATH :: ".tyr"

create_dot_tyr_dir :: proc() {
	if os.exists(DOT_TYR_PATH) {return}
	err := os.make_directory(DOT_TYR_PATH)
	if err != nil {
		panic(fmt.tprintf("failed to create " + DOT_TYR_PATH + " directory: %s", err))
	}
}
