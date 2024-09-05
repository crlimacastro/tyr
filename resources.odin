package tyr

import "core:mem"

resources :: distinct map[typeid]rawptr

resources_set :: proc(res: ^resources, $t: typeid, value: t) -> mem.Allocator_Error {
    if t not_in res {
        new_res, err := mem.alloc(size_of(t))
        res[t] = new_res
        if err != .None {
            return err
        }
    }
    resource := cast(^t)res[t]
    resource^ = value

    return .None
}

resources_get :: proc(res: ^resources, $t: typeid) -> (^t, bool) {
    if (t not_in res) {
        return nil, false
    }
    return cast(^t)res[t], true
}

resources_destroy :: proc(res: ^resources, $t: typeid) -> mem.Allocator_Error {
    if t not_in res {
        return .None
    }
    resource := cast(^t)res[t]
    delete_key(res, t)
    return mem.free(resource)
}
