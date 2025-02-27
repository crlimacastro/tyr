package tyr

import "core:math/linalg"

color :: distinct [4]u8

black :: color{0, 0, 0, 255}
white :: color{255, 255, 255, 255}
cornflower_blue :: color{100, 149, 237, 255}

clear_color :: distinct color

rectangle :: struct {
	x, y, width, height: fp,
}

pixel_format :: enum {
	unknown = 0,
	uncompressed_grayscale = 1, // 8 bit per pixel (no alpha)
	uncompressed_gray_alpha, // 8*2 bpp (2 channels)
	uncompressed_r5g6b5, // 16 bpp
	uncompressed_r8g8b8, // 24 bpp
	uncompressed_r5g5b5a1, // 16 bpp (1 bit alpha)
	uncompressed_r4g4b4a4, // 16 bpp (4 bit alpha)
	uncompressed_r8g8b8a8, // 32 bpp
	uncompressed_r32, // 32 bpp (1 channel - float)
	uncompressed_r32g32b32, // 32*3 bpp (3 channels - float)
	uncompressed_r32g32b32a32, // 32*4 bpp (4 channels - float)
	uncompressed_r16, // 16 bpp (1 channel - float)
	uncompressed_r16g16b16, // 16*3 bpp (3 channels - float)
	uncompressed_r16g16b16a16, // 16*4 bpp (4 channels - float)
	compressed_dxt1_rgb, // 4 bpp (no alpha)
	compressed_dxt1_rgba, // 4 bpp (1 bit alpha)
	compressed_dxt3_rgba, // 8 bpp
	compressed_dxt5_rgba, // 8 bpp
	compressed_etc1_rgb, // 4 bpp
	compressed_etc2_rgb, // 4 bpp
	compressed_etc2_eac_rgba, // 8 bpp
	compressed_pvrt_rgb, // 4 bpp
	compressed_pvrt_rgba, // 4 bpp
	compressed_astc_4x4_rgba, // 8 bpp
	compressed_astc_8x8_rgba, // 2 bpp
}

texture :: struct {
	id:      uint,
	width:   int, // Image base width
	height:  int, // Image base height
	mipmaps: int, // Mipmap levels, 1 by default
	format:  pixel_format, // Data format (PixelFormat type)
}

sprite :: struct {
	texture: texture,
	source:  rectangle,
	tint:    color,
	flip:    [2]bool,
}

sprite_new :: proc(texture: texture) -> sprite {
	return {
		texture = texture,
		tint = white,
		source = {0, 0, fp(texture.width), fp(texture.height)},
	}
}

mesh :: struct {
	vertex_count:   uint, // Number of vertices stored in arrays
	triangle_count: uint, // Number of triangles stored (indexed or not)

	// Default vertex data
	vertices:       [^]f32, // Vertex position (XYZ - 3 components per vertex) (shader-location = 0)
	texcoords:      [^]f32, // Vertex texture coordinates (UV - 2 components per vertex) (shader-location = 1)
	texcoords2:     [^]f32, // Vertex second texture coordinates (useful for lightmaps) (shader-location = 5)
	normals:        [^]f32, // Vertex normals (XYZ - 3 components per vertex) (shader-location = 2)
	tangents:       [^]f32, // Vertex tangents (XYZW - 4 components per vertex) (shader-location = 4)
	colors:         [^]u8, // Vertex colors (RGBA - 4 components per vertex) (shader-location = 3)
	indices:        [^]u16, // Vertex indices (in case vertex data comes indexed)

	// Animation vertex data
	anim_vertices:  [^]f32, // Animated vertex positions (after bones transformations)
	anim_normals:   [^]f32, // Animated normals (after bones transformations)
	bone_ids:       [^]u8, // Vertex bone ids, up to 4 bones influence by vertex (skinning)
	bone_weights:   [^]f32, // Vertex bone weight, up to 4 bones influence by vertex (skinning)
	vao_id:         u32, // OpenGL Vertex Array Object id
	vbo_id:         [^]u32, // OpenGL Vertex Buffer Objects id (default vertex data)
}

camera_projection :: enum {
	perspective, // Perspective projection
	orthographic, // Orthographic projection
}

camera3d :: struct {
	fovy:       f32, // Camera field-of-view apperture in Y (degrees) in perspective, used as near plane width in orthographic
	projection: camera_projection, // Camera projection: CAMERA_PERSPECTIVE or CAMERA_ORTHOGRAPHIC
}
camera :: camera3d

main_camera3d :: struct {
	entity: entity,
}
main_camera :: main_camera3d

visibility :: distinct bool

renderer :: struct {
	data:          rawptr,
	load_texture:  proc(data: rawptr, filename: string) -> texture,
	render_sprite: proc(
		data: rawptr,
		sprite: ^sprite,
		position: vec2 = {},
		rotation: fp = 0,
		scale: vec2 = {1, 1},
		tint: color = white,
		flip: [2]bool = {false, false},
	),
	render_mesh:   proc(
		data: rawptr,
		sprite: ^mesh,
		position: vec3 = {},
		rotation: vec3 = {},
		scale: vec3 = {1, 1, 1},
	),
}

renderer_load_texture :: proc(renderer: ^renderer, filename: string) -> texture {
	return renderer.load_texture(renderer.data, filename)
}

renderer_render_sprite :: proc(
	renderer: ^renderer,
	sprite: ^sprite,
	position: vec2 = {},
	rotation: fp = 0,
	scale: vec2 = {1, 1},
	tint: color = white,
	flip: [2]bool = {false, false},
) {
	renderer.render_sprite(renderer.data, sprite, position, rotation, scale, tint, flip)
}

renderer_render_mesh :: proc(
	renderer: ^renderer,
	mesh: ^mesh,
	position: vec3 = {},
	rotation: vec3 = {},
	scale: vec3 = {1, 1, 1},
) {
	renderer.render_mesh(renderer.data, mesh, position, rotation, scale)
}

rendering_step :: struct {
	using step: app_step,
	renderer:   ^renderer,
}

rendering_step_3d :: struct {
	using step: app_step,
	renderer:   ^renderer,
}


rendering_plugin :: proc(app: ^app) {
	app_add_plugins(app, raylib_plugin)
	app_set_resource(app, clear_color(black))
	app_add_systems(app, update_step, rendering_quit_on_window_should_close_system)
	app_add_systems(app, raylib_drawing_step, rendering_rendering_step_system)
	app_add_systems(app, rendering_step, rendering_render_sprites_system)
	app_add_systems(app, raylib_drawing_3d_step, rendering_rendering_step_3d_system)
	app_add_systems(app, rendering_step_3d, rendering_render_meshes_system)
}

rendering_quit_on_window_should_close_system :: proc(#by_ptr step: update_step) {
	window, ok := resources_get(step.resources, window)
	if !ok {return}
	if !window_should_close(window) {return}
	scheduler_dispatch(step.scheduler, app_quit, app_quit{step = step})
}

rendering_rendering_step_system :: proc(#by_ptr step: raylib_drawing_step) {
	renderer, ok := resources_get(step.resources, renderer)
	if !ok {
		return
	}
	scheduler_dispatch(
		step.scheduler,
		rendering_step,
		rendering_step{step = step, renderer = renderer},
	)
}

rendering_rendering_step_3d_system :: proc(#by_ptr step: raylib_drawing_3d_step) {
	renderer, ok := resources_get(step.resources, renderer)
	if !ok {
		return
	}
	scheduler_dispatch(
		step.scheduler,
		rendering_step_3d,
		rendering_step_3d{step = step, renderer = renderer},
	)
}

rendering_render_sprites_system :: proc(#by_ptr step: rendering_step) {
	for e in ecs_tquery(step.ecs_ctx, {sprite}) {
		sprite, _ := ecs_get_component(step.ecs_ctx, e, sprite)
		position: vec2
		rotation: fp
		scale: vec2 = {1, 1}
		is_visible := true
		if visibility, ok := ecs_get_component(step.ecs_ctx, e, visibility); ok {
			is_visible = bool(visibility^)
		}
		if !is_visible {
			continue
		}

		if transform, ok := ecs_get_component(step.ecs_ctx, e, transform2); ok {
			position = transform.translation
			rotation = transform.rotation
			scale = transform.scale
		}
		renderer_render_sprite(
			step.renderer,
			sprite,
			position,
			rotation,
			scale,
			sprite.tint,
			sprite.flip,
		)
	}
}

rendering_render_meshes_system :: proc(#by_ptr step: rendering_step_3d) {
	for e in ecs_tquery(step.ecs_ctx, {mesh}) {
		mesh, _ := ecs_get_component(step.ecs_ctx, e, mesh)
		position: vec3
		rotation: vec3
		scale: vec3 = {1, 1, 1}
		is_visible := true
		if visibility, ok := ecs_get_component(step.ecs_ctx, e, visibility); ok {
			is_visible = bool(visibility^)
		}
		if !is_visible {
			continue
		}


		if transform, ok := ecs_get_component(step.ecs_ctx, e, transform3); ok {
			x, y, z := linalg.euler_angles_from_quaternion(transform.rotation, .XYZ)
			rotation_euler := vec3{x, y, z}

			position = transform.translation
			rotation = rotation_euler
			scale = transform.scale
		}
		renderer_render_mesh(step.renderer, mesh, position, rotation, scale)
	}
}
