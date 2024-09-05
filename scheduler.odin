package tyr

import "core:mem"

scheduler :: distinct map[typeid]rawptr

scheduler_add_systems :: proc(
	s: ^scheduler,
	$t_event: typeid,
	systems: ..proc(#by_ptr arg: t_event),
) -> mem.Allocator_Error {
	if t_event not_in s {
		e, err := mem.alloc(size_of(event(t_event)))
		if err != .None {
			return err
		}
		s[t_event] = e
	}
	e := cast(^event(t_event))s[t_event]
	event_add_listeners(t_event, e, ..systems)
	return .None
}

scheduler_remove_systems :: proc(
	s: ^scheduler,
	$t_event: typeid,
	systems: ..proc(#by_ptr arg: t_event),
) {
	if t_event not_in s {
		return
	}
	e := cast(^event(t_event))s[t_event]
	event_remove_listeners(t_event, e, ..systems)
	if len(e.listeners) <= 0 {
		mem.free(e)
		delete_key(s, t_event)
	}
}

scheduler_clear :: proc(s: ^scheduler) {
	mem.free(s)
	clear(s)
}

scheduler_clear_systems :: proc(s: ^scheduler, $t_event: typeid) {
	if t_event not_in s {
		return
	}
	e := cast(^event(t_event))s[t_event]
	event_clear(e)
	mem.free(e)
	delete_key(s, t_event)
}

scheduler_dispatch :: proc(s: ^scheduler, $t_event: typeid, arg: t_event) {
	if t_event not_in s {
		return
	}
	e := cast(^event(t_event))s[t_event]
	event_invoke(t_event, e, arg)
}
