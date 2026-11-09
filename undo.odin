package tyr

import "core:strings"
import "base:runtime"
import "core:mem"
import "core:reflect"

undo_change :: struct {
	target: undo_target,
	type:   typeid,
	before: undo_value,
	after:  undo_value,
}

undo_change_destroy :: proc(change: ^undo_change) {
	undo_value_destroy(&change.before)
	undo_value_destroy(&change.after)
	change^ = {}
}

undo_target :: struct {
	ptr:    rawptr,
	type:   typeid,
	offset: uintptr,
}

undo_snapshot :: proc(
	ptr: rawptr,
	info: ^reflect.Type_Info,
	allocator := context.allocator,
) -> []byte

undo_restore :: proc(ptr: rawptr, info: ^reflect.Type_Info, snapshot: []byte)

undo_snapshot_value :: proc(
	ptr: rawptr,
	info: ^reflect.Type_Info,
	allocator: runtime.Allocator,
) -> undo_value {
	result := undo_value {
		type      = info.id,
		allocator = allocator,
	}

	#partial switch v in info.variant {
	case runtime.Type_Info_Named:
		return undo_snapshot_value(ptr, v.base, allocator)

	case runtime.Type_Info_String:
		value := (^string)(ptr)^

		result.data = make([]byte, len(value), allocator)
		if len(value) > 0 {
			mem.copy(raw_data(result.data), raw_data(value), len(value))
		}

	case runtime.Type_Info_Dynamic_Array:
		array := (^runtime.Raw_Dynamic_Array)(ptr)^

		result.children = make([]undo_value, array.len, allocator)

		for i in 0 ..< array.len {
			element_ptr := rawptr(uintptr(array.data) + uintptr(i * v.elem_size))

			result.children[i] = undo_snapshot_value(element_ptr, v.elem, allocator)
		}

	case runtime.Type_Info_Struct:
		result.children = make([]undo_value, int(v.field_count), allocator)

		for i in 0 ..< v.field_count {
			field_ptr := rawptr(uintptr(ptr) + v.offsets[i])

			result.children[i] = undo_snapshot_value(field_ptr, v.types[i], allocator)
		}

	case runtime.Type_Info_Map:
		// panic("undo_snapshot_value: map snapshots are not implemented")

	case:
		result.data = make([]byte, info.size, allocator)

		if info.size > 0 {
			mem.copy(raw_data(result.data), ptr, info.size)
		}
	}

	return result
}

undo_history :: struct {
	changes:     [dynamic]undo_change,
	cursor:      int,
	transaction: undo_transaction,
}

undo_history_commit :: proc(history: ^undo_history, change: undo_change) {
	// Discard redo history.
	for i in history.cursor ..< len(history.changes) {
		undo_change_destroy(&history.changes[i])
	}

	resize(&history.changes, history.cursor)

	// Append the new change.
	append(&history.changes, change)

	// Move cursor to the end.
	history.cursor = len(history.changes)
}

undo_history_undo :: proc(history: ^undo_history, ctx: ^ecs_context) {
	if history.cursor <= 0 {
		return
	}

	change := &history.changes[history.cursor - 1]

	ptr := change.target.ptr
	if ptr == nil {
		return
	}

	info := type_info_of(change.type)

	undo_restore_value(ptr, info, &change.before)

	history.cursor -= 1
}

undo_history_redo :: proc(history: ^undo_history, ctx: ^ecs_context) {
	if history.cursor >= len(history.changes) {
		return
	}

	change := &history.changes[history.cursor]

	ptr := change.target.ptr
	if ptr == nil {
		return
	}

	info := type_info_of(change.type)

	undo_restore_value(ptr, info, &change.after)

	history.cursor += 1
}

undo_transaction :: struct {
	active: bool,
	target: undo_target,
	type:   typeid,
	before: undo_value,
}

undo_transaction_begin :: proc(
	history: ^undo_history,
	target: undo_target,
	info: ^reflect.Type_Info,
	ptr: rawptr,
	allocator: runtime.Allocator,
) {
	if history.transaction.active {
		return
	}

	history.transaction = undo_transaction {
		active = true,
		target = target,
		type   = info.id,
		before = undo_snapshot_value(ptr, info, allocator),
	}
}

undo_transaction_commit :: proc(history: ^undo_history, ctx: ^ecs_context) {
	transaction := &history.transaction

	if !transaction.active {
		return
	}

	ptr := transaction.target.ptr
	if ptr == nil {
		undo_value_destroy(&transaction.before)
		transaction^ = {}
		return
	}

	info := type_info_of(transaction.type)
	after := undo_snapshot_value(ptr, info, context.allocator)

	change := undo_change {
		target = transaction.target,
		type   = transaction.type,
		before = transaction.before,
		after  = after,
	}

	// ownership of before has moved into change.
	transaction^ = {}

	undo_history_commit(history, change)
}

undo_transaction_cancel :: proc(history: ^undo_history) {
	if !history.transaction.active {
		return
	}

	undo_value_destroy(&history.transaction.before)
	history.transaction = {}
}

undo_value :: struct {
	type:      typeid,
	allocator: runtime.Allocator,
	data:      []byte,
	children:  []undo_value,
}

undo_value_destroy :: proc(value: ^undo_value) {
	for i in 0 ..< len(value.children) {
		undo_value_destroy(&value.children[i])
	}

	delete(value.children, value.allocator)
	delete(value.data, value.allocator)

	value^ = {}
}

undo_restore_value :: proc(
	ptr: rawptr,
	info: ^reflect.Type_Info,
	value: ^undo_value,
) {
	#partial switch v in info.variant {
	case runtime.Type_Info_Named:
		undo_restore_value(ptr, v.base, value)

	case runtime.Type_Info_String:
		current := (^string)(ptr)^

		if len(current) > 0 {
			delete(current)
		}

		sb : strings.Builder
		strings.builder_init_len(&sb, len(value.data), allocator=value.allocator)
		result := strings.to_string(sb)

		if len(value.data) > 0 {
			mem.copy(
				raw_data(result),
				raw_data(value.data),
				len(value.data),
			)
		}

		(^string)(ptr)^ = result

	case runtime.Type_Info_Dynamic_Array:
		array := (^runtime.Raw_Dynamic_Array)(ptr)

		// Release the previous allocation.
		if array.data != nil {
			// Existing elements may own allocations themselves.
			for i in 0 ..< array.len {
				element_ptr := rawptr(
					uintptr(array.data) + uintptr(i) * uintptr(v.elem_size),
				)

				undo_restore_value(
					element_ptr,
					v.elem,
					value
				)
			}

			// Release the array backing storage.
			// Use the allocator that originally allocated it.
			free(array.data)
		}

		array.data = nil
		array.len = 0
		array.cap = 0

		if len(value.children) == 0 {
			return
		}

		array.data = raw_data(make(
			[]u8,
			len(value.children) * int(v.elem_size),
			value.allocator,
		))
		array.len = len(value.children)
		array.cap = len(value.children)

		for i in 0 ..< len(value.children) {
			element_ptr := rawptr(
				uintptr(array.data) + uintptr(i) * uintptr(v.elem_size),
			)

			undo_restore_value(
				element_ptr,
				v.elem,
				&value.children[i],
			)
		}

	case runtime.Type_Info_Struct:
		for i in 0 ..< v.field_count {
			field_ptr := rawptr(
				uintptr(ptr) + v.offsets[i],
			)

			undo_restore_value(
				field_ptr,
				v.types[i],
				&value.children[i],
			)
		}

	case runtime.Type_Info_Map:
		panic("undo_restore_value: map restoration is not implemented")

	case:
		if info.size > 0 {
			mem.copy(
				ptr,
				raw_data(value.data),
				info.size,
			)
		}
	}
}
