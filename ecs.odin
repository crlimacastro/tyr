package tyr

import ecs "odin-ecs"

entity :: distinct u64

ecs_context :: struct {
	__ctx: ecs.Context,
}

ecs_init :: proc() -> ecs_context {
	return ecs_context{__ctx = ecs.init_ecs()}
}

ecs_deinit :: proc(ctx: ^ecs_context) {
	ecs.deinit_ecs(&ctx.__ctx)
}

ecs_create_entity :: proc(ctx: ^ecs_context) -> entity {
	return entity(ecs.create_entity(&ctx.__ctx))
}

ecs_set_component :: proc(ctx: ^ecs_context, entity: entity, component: $t) {
	e := ecs.Entity(entity)

	if !ecs.has_component(&ctx.__ctx, e, t) {
		ecs.add_component(&ctx.__ctx, e, component)
	} else {
		ecs.set_component(&ctx.__ctx, e, component)
	}
}

ecs_get_component :: proc(ctx: ^ecs_context, entity: entity, $t: typeid) -> (^t, bool) {
	component, err := ecs.get_component(&ctx.__ctx, ecs.Entity(entity), t)
	if err == .NO_ERROR {
		return cast(^t)component, true
	}
	return nil, false
}

ecs_query :: proc(
	ctx: ^ecs_context,
	components: []typeid,
	allocator := context.allocator,
) -> [dynamic]entity {
	ecs_entities := ecs.get_entities_with_components(&ctx.__ctx, components)
	entities := make([dynamic]entity)
	for e in ecs_entities {
		append(&entities, entity(e))
	}
	return entities
}

ecs_tquery :: proc(ctx: ^ecs_context, components: []typeid) -> [dynamic]entity {
	return ecs_query(ctx, components, context.temp_allocator)
}

ecs_get_entities :: proc(ctx: ^ecs_context, allocator := context.allocator) -> [dynamic]entity {
	entities := make([dynamic]entity)
	for e in ctx.__ctx.entities.entities {
		append(&entities, entity(e.entity))
	}
	return entities
}

ecs_entity_is_valid :: proc(ctx: ^ecs_context, entity: entity) -> bool {
	return ecs.is_entity_valid(&ctx.__ctx, ecs.Entity(entity))
}

typeid_and_rawptr :: struct {
	id: typeid,
	ptr: rawptr,
}

ecs_get_components_of_entity :: proc(ctx: ^ecs_context, entity: entity, allocator := context.allocator) -> [dynamic]typeid_and_rawptr {
	components := make([dynamic]typeid_and_rawptr, allocator)
	e := ecs.Entity(entity)
	for component_type in ctx.__ctx.component_map {
		components_of_type := ctx.__ctx.component_map[component_type]

		array := cast(^[dynamic]rawptr)components_of_type.data
		index, is_entity_a_key := components_of_type.entity_indices[e]
		
		if is_entity_a_key {
			append(&components, typeid_and_rawptr{component_type, &array[index]})
		}
	}
	return components
}