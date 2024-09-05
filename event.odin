package tyr

event :: struct($t_arg: typeid) {
	listeners: [dynamic]proc(#by_ptr arg: t_arg),
}

event_add_listeners :: proc(
	$t_arg: typeid,
	e: ^event(t_arg),
	listeners: ..proc(#by_ptr arg: t_arg),
) {
    append_elems(&e.listeners, ..listeners)
}

event_remove_listeners :: proc(
	$t_arg: typeid,
	e: ^event(t_arg),
	listeners: ..proc(#by_ptr arg: t_arg),
) {
	for listener in listeners {
		for l, i in e.listeners {
			if l == listener {
				ordered_remove(&e.listeners, i)
				return
			}
		}
	}
}

event_rremove_listeners :: proc(
	$t_arg: typeid,
	e: ^event(t_arg),
	listeners: ..proc(#by_ptr arg: t_arg),
) {
	for listener in listeners {
		#reverse for l, i in e.listeners {
			if l == listener {
				ordered_remove(&e.listeners, i)
				return
			}
		}
	}
}

event_invoke :: proc($t_arg: typeid, e: ^event(t_arg), arg: t_arg) {
	for listener in e.listeners {
		listener(arg)
	}
}

event_rinvoke :: proc($t_arg: typeid, e: ^event(t_arg), arg: t_arg) {
	#reverse for listener in e.listeners {
		listener(arg)
	}
}

event_clear :: proc($t_arg: typeid, e: ^event(t_arg)) {
	clear(&e.listeners)
}
