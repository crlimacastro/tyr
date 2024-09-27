package tyr

import "core:testing"

@(test)
component_test :: proc(test: ^testing.T) {
	test_rect :: struct {
		x, y:          f32,
		width, height: f32,
	}

	test_string :: distinct string

	ctx := ecs_context_init()
	defer ecs_context_deinit(&ctx)

	entity := ecs_create_entity(&ctx)

	test_comp_value := test_rect {
		x      = 20,
		y      = 20,
		width  = 64,
		height = 64,
	}

	is_component_added_properly :: proc(
		ctx: ^ecs_context,
		test: ^testing.T,
		entity: entity,
		component: $t,
	) -> ^t {

		comp := ecs_add_component(ctx, entity, component)
		is_returned_comp_equal := comp^ == component
		testing.expect(
			test,
			is_returned_comp_equal == true,
			"the returned component is not equal to the original component passed in.",
		)

		is_type_in_map := t in ctx.component_map
		testing.expect(test, is_type_in_map == true, "failed to register the component type!")
		return comp
	}

	sprite_comp := is_component_added_properly(&ctx, test, entity, test_comp_value)
	name_comp := is_component_added_properly(&ctx, test, entity, test_string("Test Name"))

	is_component_removed_properly :: proc(
		ctx: ^ecs_context,
		test: ^testing.T,
		entity: entity,
		$t: typeid,
	) {
		old_entity_index := ctx.component_map[t].entity_indices[entity]

		removed := ecs_remove_component(ctx, entity, t)
		testing.expect_value(test, removed, true)

		is_entity_index_valid := entity in ctx.component_map[t].entity_indices
		testing.expect(
			test,
			is_entity_index_valid == false,
			"the key should be deleted after the entity removes the component.",
		)
	}

	is_component_removed_properly(&ctx, test, entity, test_rect)
	is_component_removed_properly(&ctx, test, entity, test_string)
}

@(test)
entity_test :: proc(test: ^testing.T) {
	ctx := ecs_context_init()
	defer ecs_context_deinit(&ctx)

	entities: [100]entity
	for i in 0 ..< len(entities) {
		entities[i] = ecs_create_entity(&ctx)
		testing.expect_value(test, uint(entities[i]), uint(i))

		is_valid := ecs_is_entity_valid(&ctx, entities[i])
		testing.expect(test, is_valid == true, "entity should be valid!")
	}

	// Delete the entities. The entities should be put on the available_slots queue, so we can reuse that index later.
	for i in 0 ..< len(entities) {
		ecs_destroy_entity(&ctx, entities[i])
		is_valid := ecs_is_entity_valid(&ctx, entities[i])
		testing.expect(
			test,
			is_valid == false,
			"entity should not be valid after deleting an entity!",
		)
	}

	// The entity ids should be the same since we deleted all of the old entities.
	for i in 0 ..< len(entities) {
		entities[i] = ecs_create_entity(&ctx)
		testing.expect_value(test, uint(entities[i]), uint(i))
	}

}
