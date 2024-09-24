package tyr

import "core:fmt"
import "core:mem"

resources :: distinct map[typeid]rawptr

resources_set :: proc(res: ^resources, value: $t) {
	if t not_in res {
		new_res, err := mem.alloc(size_of(t))
		if err != .None {
			panic(fmt.tprintf("failed to allocate resource: %s", err))
		}
		res[t] = new_res
	}
	resource := cast(^t)res[t]
	resource^ = value
}

resources_get :: proc(res: ^resources, $t: typeid) -> (^t, bool) {
	if (t not_in res) {
		return nil, false
	}
	return cast(^t)res[t], true
}

resources_get_or_make :: proc(res: ^resources, $t: typeid) -> ^t {
	if (t not_in res) {
		new_res, err := mem.alloc(size_of(t))
		if err != .None {
			panic(fmt.tprintf("failed to allocate resource: %s", err))
		}
		res[t] = new_res
	}
	return cast(^t)res[t]
}

resources_destroy :: proc(res: ^resources, $t: typeid) {
	if t not_in res {
		return .None
	}
	resource := cast(^t)res[t]
	delete_key(res, t)
	mem.free(resource)
}
