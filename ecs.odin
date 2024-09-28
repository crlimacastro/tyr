package tyr

import "base:intrinsics"
import "base:runtime"
import "core:container/queue"
import "core:slice"

entity :: distinct uint

ecs_context :: struct {
	current_entity_id: uint,
	entities:          map[entity]bool,
	available_slots:   queue.Queue(uint),
	component_map:     map[typeid]component_list,
}

component_list :: struct {
	type:           typeid,
	data:           ^runtime.Raw_Dynamic_Array,
	entity_indices: map[entity]uint,
}

ecs_context_init :: proc() -> ecs_context {
	ctx: ecs_context
	ctx.entities = make(map[entity]bool)
	queue.init(&ctx.available_slots)
	ctx.component_map = make(map[typeid]component_list)
	return ctx
}

ecs_context_deinit :: proc(ctx: ^ecs_context) {
	ctx.current_entity_id = 0
	delete(ctx.entities)
	queue.destroy(&ctx.available_slots)

	for key, value in ctx.component_map {
		free(value.data^.data)
		free(value.data)
		delete(value.entity_indices)
	}
	delete(ctx.component_map)
}

ecs_get_entities :: proc(ctx: ^ecs_context, allocator := context.allocator) -> []entity {
	entities := make([]entity, len(ctx.entities), allocator)
	i := 0
	for key, _ in ctx.entities {
		entities[i] = key
		i+=1
	}
	
	return entities
}

ecs_add_component :: proc(ctx: ^ecs_context, entity: entity, component: $t) -> ^t {
	if t not_in ctx.component_map {
		array := new([dynamic]t)
		ctx.component_map[t] = {
			type = t,
			data = cast(^runtime.Raw_Dynamic_Array)array,
		}
		array^ = make_dynamic_array([dynamic]t)
	}

	array := cast(^[dynamic]t)ctx.component_map[t].data
	comp_map := &ctx.component_map[t]

	// Add a new component to the component array.
	append_elem(array, component)
	// Map the entity to the new index, so we can lookup the component index later,
	comp_map.entity_indices[entity] = len(array) - 1

	return &array[comp_map.entity_indices[entity]]
}

ecs_set_component :: proc(ctx: ^ecs_context, entity: entity, component: $t) {
	if !ecs_has_component(ctx, entity, t) {
		ecs_add_component(ctx, entity, component)
		return
	}
	index, is_entity_a_key := ctx.component_map[t].entity_indices[entity]

	if !is_entity_a_key {
		return
	}
	array := cast(^[dynamic]t)ctx.component_map[t].data
	array[index] = component
}

ecs_has_component :: proc(ctx: ^ecs_context, entity: entity, t: typeid) -> bool {
	if t not_in ctx.component_map {
		return false
	}
	return entity in (&ctx.component_map[t]).entity_indices
}

ecs_remove_component :: proc(
	ctx: ^ecs_context,
	entity: entity,
	type_id: typeid,
) -> (
	removed: bool,
) {
	if !ecs_has_component(ctx, entity, type_id) {
		return false
	}
	index := ctx.component_map[type_id].entity_indices[entity]

	array_len := ctx.component_map[type_id].data^.len
	array := ctx.component_map[type_id].data^.data
	comp_map := ctx.component_map[type_id]

	info := type_info_of(type_id)
	struct_size := info.size
	array_in_bytes := slice.bytes_from_ptr(array, array_len * struct_size)

	byte_index := int(index) * struct_size
	last_byte_index := (len(array_in_bytes)) - struct_size
	e_index := comp_map.entity_indices[entity]
	e_back := uint(array_len - 1)
	if e_index != e_back {
		slice.swap_with_slice(
			array_in_bytes[byte_index:byte_index + struct_size],
			array_in_bytes[last_byte_index:],
		)
		// TODO: Remove this and replace it with something that dosen't have to do a lot of searching.
		for _, &value in comp_map.entity_indices {
			if value == e_back {value = e_index}
		}
	}

	// TODO: Handle resize errors
	resize_allocator_error := _resize_raw_dynamic_array(
		ctx.component_map[type_id].data,
		struct_size,
		info.align,
		ctx.component_map[type_id].data^.len - 1,
		true,
	)
	if resize_allocator_error != .None {
		panic("failed to resize the component list.")
	}

	delete_key(&comp_map.entity_indices, entity)

	return true
}

ecs_remove_components :: proc(ctx: ^ecs_context, entity: entity, component_ts: ..typeid) {
	for component_t in component_ts {
		ecs_remove_component(ctx, entity, component_t)
	}
}

ecs_get_component :: proc(
	ctx: ^ecs_context,
	entity: entity,
	$t: typeid,
) -> (
	component: ^t,
	ok: bool,
) {
	if !ecs_has_component(ctx, entity, t) {
		return nil, false
	}

	array := cast(^[dynamic]t)ctx.component_map[t].data
	index, is_entity_a_key := ctx.component_map[t].entity_indices[entity]

	if !is_entity_a_key {
		return nil, false
	}

	return &array[index], true
}

ecs_get_components :: proc(ctx: ^ecs_context, entity: entity, ts: ..$t) -> []^t {

	for t in ts {
		comp, err := get_component(ctx, entity, t)
	}
	return a, b, c, d, e, {}
}

ecs_get_component_slice_from_entities :: proc(
	ctx: ^ecs_context,
	entities: []entity,
	$t: typeid,
	allocator := context.allocator,
) -> []^t {
	context.user_ptr = ctx
	get_t_proc :: proc(h: entity) -> ^t {
		e, err := get_component(cast(^ecs_context)context.user_ptr, h, t) or_else nil
		return e
	}
	return slice.mapper(entities, get_t_proc)
}

ecs_get_component_list :: proc(ctx: ^ecs_context, $t: typeid) -> []t {
	array := cast(^[dynamic]t)ctx.component_map[t].data
	if array == nil {
		return {}
	}
	return array[:]
}

ecs_create_entity :: proc(ctx: ^ecs_context) -> entity {
	if queue.len(ctx.available_slots) <= 0 {
		ctx.entities[entity(ctx.current_entity_id)] = true
		ctx.current_entity_id += 1
		return entity(ctx.current_entity_id - 1)
	} else {
		index := queue.pop_front(&ctx.available_slots)
		ctx.entities[entity(index)] = true
		return entity(index)
	}
}

ecs_is_entity_valid :: proc(ctx: ^ecs_context, entity: entity) -> bool {
	return entity in ctx.entities
}

// This is slow. 
// This will be significantly faster when an archetype or sparse set ECS is implemented.
ecs_query :: proc(
	ctx: ^ecs_context,
	components: []typeid,
	allocator := context.allocator,
) -> (
	entities: [dynamic]entity,
) {
	entities = make([dynamic]entity, allocator)

	if len(components) <= 0 {
		return entities
	} else if len(components) == 1 {
		for entity, _ in ctx.component_map[components[0]].entity_indices {
			append_elem(&entities, entity)
		}
		return entities
	}

	for entity, _ in ctx.component_map[components[0]].entity_indices {

		has_all_components := true
		for comp_type in components[1:] {
			if !ecs_has_component(ctx, entity, comp_type) {
				has_all_components = false
				break
			}
		}

		if has_all_components {
			append_elem(&entities, entity)
		}
	}

	return entities
}

ecs_tquery :: proc(ctx: ^ecs_context, components: []typeid) -> [dynamic]entity {
	return ecs_query(ctx, components, context.temp_allocator)
}

ecs_destroy_entity :: proc(ctx: ^ecs_context, entity: entity) {
	for t, component in &ctx.component_map {
		ecs_remove_component(ctx, entity, t)
	}

	delete_key(&ctx.entities, entity)
	queue.push_back(&ctx.available_slots, uint(entity))
}

ecs_get_components_of_entity :: proc(
	ctx: ^ecs_context,
	entity: entity,
	allocator := context.allocator,
) -> [dynamic]any {
	components := make([dynamic]any, allocator)
	for component_type in ctx.component_map {
		components_of_type := ctx.component_map[component_type]

		array := cast(^[dynamic]rawptr)components_of_type.data
		index, is_entity_a_key := components_of_type.entity_indices[entity]

		if is_entity_a_key {
			append(&components, any{&array[index], component_type})
		}
	}
	return components
}

// Copied and adjusted from here: https://github.com/odin-lang/Odin/blob/8fd318ea7a76b75974c834bb9d329958c81ce652/base/runtime/core_builtin.odin#L736
@(private = "file")
// `resize_raw_dynamic_array` will try to resize memory of a passed raw dynamic array or map to the requested element count (setting the `len`, and possibly `cap`).
_resize_raw_dynamic_array :: #force_inline proc(
	array: rawptr,
	elem_size, elem_align: int,
	length: int,
	should_zero: bool,
	loc := #caller_location,
) -> runtime.Allocator_Error {
	if array == nil {
		return nil
	}
	a := (^runtime.Raw_Dynamic_Array)(array)

	if length <= a.cap {
		if should_zero && a.len < length {
			intrinsics.mem_zero(
				([^]byte)(a.data)[a.len * elem_size:],
				(length - a.len) * elem_size,
			)
		}
		a.len = max(length, 0)
		return nil
	}

	if a.allocator.procedure == nil {
		a.allocator = context.allocator
	}
	assert(a.allocator.procedure != nil)

	old_size := a.cap * elem_size
	new_size := length * elem_size
	allocator := a.allocator

	new_data: []byte
	if should_zero {
		new_data = runtime.mem_resize(
			a.data,
			old_size,
			new_size,
			elem_align,
			allocator,
			loc,
		) or_return
	} else {
		new_data = runtime.non_zero_mem_resize(
			a.data,
			old_size,
			new_size,
			elem_align,
			allocator,
			loc,
		) or_return
	}
	if new_data == nil && new_size > 0 {
		return .Out_Of_Memory
	}

	a.data = raw_data(new_data)
	a.len = length
	a.cap = length
	return nil
}
