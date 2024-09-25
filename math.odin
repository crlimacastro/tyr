package tyr

fp :: f32 // library canonical floating point type
vec2 :: [2]fp
vec3 :: [3]fp
vec4 :: [4]fp
quat :: quaternion128

transform2 :: struct {
	translation: vec2,
	rotation:    fp,
	scale:       vec2,
}
transform3 :: struct {
	translation: vec3,
	rotation:    quat,
	scale:       vec3,
}
transform :: transform3

transform2_default :: proc() -> transform2 {
	return transform2{
		translation = {0, 0},
		rotation = 0,
		scale = {1, 1},
	}
}

transform3_default :: proc() -> transform {
	return transform{
		translation = {0, 0, 0},
		rotation = quaternion(x=0, y=0, z=0, w=1),
		scale = {1, 1, 1},
	}
}

transform3_from_translation :: proc(translation: vec3) -> transform {
	transform := transform3_default()
	transform.translation = translation
	return transform
}

transform3_from_rotation :: proc(rotation: quat) -> transform {
	transform := transform3_default()
	transform.rotation = rotation
	return transform
}

transform3_from_scale :: proc(scale: vec3) -> transform {
	transform := transform3_default()
	transform.scale = scale
	return transform
}