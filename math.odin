package tyr

fp :: f32 // floating point type
vec2 :: [2]fp
vec3 :: [3]fp
vec4 :: [4]fp
quat :: quaternion128

transform :: struct {
	translation: vec3,
	rotation:    quat,
	scale:       vec3,
}

transform_default :: proc() -> transform {
	return transform{
		translation = {0, 0, 0},
		rotation = quaternion(x=0, y=0, z=0, w=1),
		scale = {1, 1, 1},
	}
}

transform_from_translation :: proc(translation: vec3) -> transform {
	transform := transform_default()
	transform.translation = translation
	return transform
}

transform_from_rotation :: proc(rotation: quat) -> transform {
	transform := transform_default()
	transform.rotation = rotation
	return transform
}

transform_from_scale :: proc(scale: vec3) -> transform {
	transform := transform_default()
	transform.scale = scale
	return transform
}