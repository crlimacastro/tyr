package tyr

import mu "vendor:microui"
import ecs "odin-ecs"

ui_step :: struct {
	using step: app_step,
	mu_ctx:       ^mu.Context,
}

ui_plugin :: proc(app: ^app) {
	app_add_plugins(app, microui_raylib_impl_plugin)
	app_add_systems(app, microui_raylib_impl_step, ui_update_system)
}

ui_update_system :: proc(#by_ptr step: microui_raylib_impl_step) {
	scheduler_dispatch(
		step.scheduler,
		ui_step,
		ui_step{resources = step.resources, scheduler = step.scheduler, mu_ctx = step.mu_ctx, ecs_ctx = step.ecs_ctx},
	)
}

color_picker_rgba :: proc(ctx: ^mu.Context, r: ^u8, g: ^u8, b: ^u8, a: ^u8) {
	prev_spacing := ctx.style.spacing
	ctx.style.spacing = 10
	label_w := i32(10)
	square_w := i32(20)
	slider_w := i32(f32(mu.get_current_container(ctx).body.w) * (1.0 / 4.0) - f32(label_w * 4.0))
	mu.layout_row(
		ctx,
		[]i32{label_w, slider_w, label_w, slider_w, label_w, slider_w, label_w, slider_w, square_w}
	)
	mu.text(ctx, "R")
	rf := f32(r^)
	mu.slider(ctx, &rf, 0, 255, 1)
	mu.text(ctx, "G")
	gf := f32(g^)
	mu.slider(ctx, &gf, 0, 255, 1)
	mu.text(ctx, "B")
	bf := f32(b^)
	mu.slider(ctx, &bf, 0, 255, 1)
	mu.text(ctx, "A")
	af := f32(a^)
	mu.slider(ctx, &af, 0, 255, 1)
	r^ = u8(rf)
	g^ = u8(gf)
	b^ = u8(bf)
	a^ = u8(af)
	mu.draw_rect(ctx, mu.layout_next(ctx), mu.Color{r^, g^, b^, a^})
	ctx.style.spacing = prev_spacing
}

color_picker_rgb :: proc(ctx: ^mu.Context, r: ^u8, g: ^u8, b: ^u8) {
	prev_spacing := ctx.style.spacing
	ctx.style.spacing = 10
	label_w := i32(10)
	square_w := i32(20)
	slider_w := i32(f32(mu.get_current_container(ctx).body.w) * (1.0 / 4.0) - f32(label_w * 4.0))
	mu.layout_row(
		ctx,
		[]i32{label_w, slider_w, label_w, slider_w, label_w, slider_w, square_w}
	)
	mu.text(ctx, "R")
	rf := f32(r^)
	mu.slider(ctx, &rf, 0, 255, 1)
	mu.text(ctx, "G")
	gf := f32(g^)
	mu.slider(ctx, &gf, 0, 255, 1)
	mu.text(ctx, "B")
	bf := f32(b^)
	mu.slider(ctx, &bf, 0, 255, 1)
	r^ = u8(rf)
	g^ = u8(gf)
	b^ = u8(bf)
	mu.draw_rect(ctx, mu.layout_next(ctx), mu.Color{r^, g^, b^, 255})
	ctx.style.spacing = prev_spacing
}