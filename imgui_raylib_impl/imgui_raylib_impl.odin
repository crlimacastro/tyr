package imgui_raylib_impl

// Based on the raylib extras rlImGui: https://github.com/raylib-extras/rlImGui/blob/main/rlim.cpp
/* Usage:
import im_rl "imgui_impl_raylib"
import im "odin-imgui"
main :: proc() {
    rl.SetConfigFlags({ rl.ConfigFlag.WINDOW_RESIZABLE })
    rl.InitWindow(800, 600, "raylib basic window")
    defer rl.CloseWindow()
    im.CreateContext(nil)
	defer im.DestroyContext(nil)
    im_rl.init()
	defer im_rl.shutdown()
    im_rl.build_font_atlas()
    for !rl.WindowShouldClose() {
		im_rl.process_events()
		im_rl.new_frame()
		im.NewFrame()
        rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)
        im.ShowDemoWindow(nil)
        im.Render()
		im_rl.render_draw_data(im.GetDrawData())
        rl.EndDrawing()
    }
}
*/

import "core:c"
import "core:math"
import "core:mem"

// Follow build instruction for imgui bindings in: https://gitlab.com/L-4/odin-imgui
import im "../odin-imgui"
import rl "vendor:raylib"
import "vendor:raylib/rlgl"

current_mouse_cursor: im.MouseCursor = im.MouseCursor.COUNT
mouse_cursor_map: [im.MouseCursor.COUNT]rl.MouseCursor

last_frame_focused := false
last_control_pressed := false
last_shift_pressed := false
last_alt_pressed := false
last_super_pressed := false

raylib_key_map: map[rl.KeyboardKey]im.Key = {}

init :: proc() -> bool {
	setup_globals()
	setup_keymap()
	setup_mouse_cursor()
	setup_backend()

	return true
}

build_font_atlas :: proc() -> mem.Allocator_Error {
	io: ^im.IO = im.GetIO()

	pixels: ^c.uchar
	width, height: c.int
	im.FontAtlas_GetTexDataAsRGBA32(io.Fonts, &pixels, &width, &height, nil)
	image: rl.Image = rl.GenImageColor(width, height, rl.BLANK)
	mem.copy(image.data, pixels, int(width * height * 4))

	font_texture: ^rl.Texture2D = transmute(^rl.Texture)io.Fonts.TexID
	if font_texture != nil && font_texture.id != 0 {
		rl.UnloadTexture(font_texture^)
		mem.free(font_texture)
	}

	font_texture =
	cast(^rl.Texture2D)(mem.alloc(size_of(rl.Texture2D), align_of(rl.Texture2D)) or_return)
	font_texture^ = rl.LoadTextureFromImage(image)
	rl.UnloadImage(image)
	io.Fonts.TexID = font_texture

	return nil
}

shutdown :: proc() {
	io: ^im.IO = im.GetIO()
	font_texture: ^rl.Texture2D = transmute(^rl.Texture)io.Fonts.TexID

	if font_texture != nil && font_texture.id != 0 {
		rl.UnloadTexture(font_texture^)
		mem.free(font_texture)
	}

	io.Fonts.TexID = nil
}

new_frame :: proc() {
	io: ^im.IO = im.GetIO()

	if rl.IsWindowFullscreen() {
		monitor := rl.GetCurrentMonitor()
		io.DisplaySize.x = f32(rl.GetMonitorWidth(monitor))
		io.DisplaySize.y = f32(rl.GetMonitorHeight(monitor))
	} else {
		io.DisplaySize.x = f32(rl.GetScreenWidth())
		io.DisplaySize.y = f32(rl.GetScreenHeight())
	}

	io.DisplayFramebufferScale = rl.GetWindowScaleDPI()
	io.DeltaTime = rl.GetFrameTime()

	if io.WantSetMousePos {
		rl.SetMousePosition(c.int(io.MousePos.x), c.int(io.MousePos.y))
	} else {
		mouse_pos := rl.GetMousePosition()
		im.IO_AddMousePosEvent(io, mouse_pos.x, mouse_pos.y)
	}

	set_mouse_event :: proc(io: ^im.IO, rl_mouse: rl.MouseButton, im_mouse: c.int) {
		if rl.IsMouseButtonPressed(rl_mouse) {
			im.IO_AddMouseButtonEvent(io, im_mouse, true)
		} else if rl.IsMouseButtonReleased(rl_mouse) {
			im.IO_AddMouseButtonEvent(io, im_mouse, false)
		}
	}

	set_mouse_event(io, rl.MouseButton.LEFT, c.int(im.MouseButton.Left))
	set_mouse_event(io, rl.MouseButton.RIGHT, c.int(im.MouseButton.Right))
	set_mouse_event(io, rl.MouseButton.MIDDLE, c.int(im.MouseButton.Middle))
	set_mouse_event(io, rl.MouseButton.FORWARD, c.int(im.MouseButton.Middle) + 1)
	set_mouse_event(io, rl.MouseButton.BACK, c.int(im.MouseButton.Middle) + 2)

	mouse_wheel := rl.GetMouseWheelMoveV()
	im.IO_AddMouseWheelEvent(io, mouse_wheel.x, mouse_wheel.y)

	if im.ConfigFlag.NoMouseCursorChange not_in io.ConfigFlags {
		im_cursor: im.MouseCursor = im.GetMouseCursor()
		if im_cursor != current_mouse_cursor || io.MouseDrawCursor {
			current_mouse_cursor = im_cursor
			if io.MouseDrawCursor || im_cursor == im.MouseCursor.None {
				rl.HideCursor()
			} else {
				rl.ShowCursor()
				if c.int(im_cursor) > -1 && im_cursor < im.MouseCursor.COUNT {
					rl.SetMouseCursor(mouse_cursor_map[im_cursor])
				} else {
					rl.SetMouseCursor(rl.MouseCursor.DEFAULT)
				}
			}
		}
	}
}

render_draw_data :: proc(draw_data: ^im.DrawData) {
	rlgl.DrawRenderBatchActive()
	rlgl.DisableBackfaceCulling()

	command_lists: []^im.DrawList = mem.slice_ptr(
		draw_data.CmdLists.Data,
		int(draw_data.CmdLists.Size),
	)
	for command_list in command_lists {
		cmd_slice: []im.DrawCmd = mem.slice_ptr(
			command_list.CmdBuffer.Data,
			int(command_list.CmdBuffer.Size),
		)
		for i in 0 ..< command_list.CmdBuffer.Size {
			cmd := cmd_slice[i]
			enable_scissor(
				cmd.ClipRect.x - draw_data.DisplayPos.x,
				cmd.ClipRect.y,
				cmd.ClipRect.z - (cmd.ClipRect.x - draw_data.DisplayPos.x),
				cmd.ClipRect.w - (cmd.ClipRect.y - draw_data.DisplayPos.y),
			)

			if cmd.UserCallback != nil {
				cmd.UserCallback(command_list, &cmd)
				continue
			}

			render_triangles(
				cmd.ElemCount,
				cmd.IdxOffset,
				command_list.IdxBuffer,
				command_list.VtxBuffer,
				cmd.TextureId,
			)
			rlgl.DrawRenderBatchActive()
		}
	}

	rlgl.SetTexture(0)
	rlgl.DisableScissorTest()
	rlgl.EnableBackfaceCulling()
}

@(private)
enable_scissor :: proc(x: f32, y: f32, width: f32, height: f32) {
	rlgl.EnableScissorTest()
	io: ^im.IO = im.GetIO()

	rlgl.Scissor(
		i32(x * io.DisplayFramebufferScale.x),
		i32((io.DisplaySize.y - math.floor(y + height)) * io.DisplayFramebufferScale.y),
		i32(width * io.DisplayFramebufferScale.x),
		i32(height * io.DisplayFramebufferScale.y),
	)
}

@(private)
render_triangles :: proc(
	count: u32,
	index_start: u32,
	index_buffer: im.Vector_DrawIdx,
	vert_buffer: im.Vector_DrawVert,
	texture_ptr: im.TextureID,
) {
	if count < 3 {
		return
	}

	texture: ^rl.Texture = transmute(^rl.Texture)texture_ptr

	texture_id: u32 = (texture == nil) ? 0 : texture.id

	rlgl.Begin(rlgl.TRIANGLES)
	rlgl.SetTexture(texture_id)

	index_slice: []im.DrawIdx = mem.slice_ptr(index_buffer.Data, int(index_buffer.Size))
	vert_slice: []im.DrawVert = mem.slice_ptr(vert_buffer.Data, int(vert_buffer.Size))

	for i: u32 = 0; i <= (count - 3); i += 3 {
		if rlgl.CheckRenderBatchLimit(3) != 0 {
			rlgl.Begin(rlgl.TRIANGLES)
			rlgl.SetTexture(texture_id)
		}

		index_a := index_slice[index_start + i]
		index_b := index_slice[index_start + i + 1]
		index_c := index_slice[index_start + i + 2]

		vertex_a := vert_slice[index_a]
		vertex_b := vert_slice[index_b]
		vertex_c := vert_slice[index_c]

		draw_triangle_vert :: proc(vert: im.DrawVert) {
			c: rl.Color = transmute(rl.Color)vert.col
			rlgl.Color4ub(c.r, c.g, c.b, c.a)
			rlgl.TexCoord2f(vert.uv.x, vert.uv.y)
			rlgl.Vertex2f(vert.pos.x, vert.pos.y)
		}

		draw_triangle_vert(vertex_a)
		draw_triangle_vert(vertex_b)
		draw_triangle_vert(vertex_c)
	}

	rlgl.End()
}

is_control_down :: proc() -> bool {return(
		rl.IsKeyDown(rl.KeyboardKey.RIGHT_CONTROL) ||
		rl.IsKeyDown(rl.KeyboardKey.LEFT_CONTROL) \
	)}
is_shift_down :: proc() -> bool {return(
		rl.IsKeyDown(rl.KeyboardKey.RIGHT_SHIFT) ||
		rl.IsKeyDown(rl.KeyboardKey.LEFT_SHIFT) \
	)}
is_alt_down :: proc() -> bool {return(
		rl.IsKeyDown(rl.KeyboardKey.RIGHT_ALT) ||
		rl.IsKeyDown(rl.KeyboardKey.LEFT_ALT) \
	)}
is_super_down :: proc() -> bool {return(
		rl.IsKeyDown(rl.KeyboardKey.RIGHT_SUPER) ||
		rl.IsKeyDown(rl.KeyboardKey.LEFT_SUPER) \
	)}

process_events :: proc() -> bool {
	io: ^im.IO = im.GetIO()

	focused := rl.IsWindowFocused()
	if (focused != last_frame_focused) {
		im.IO_AddFocusEvent(io, focused)
	}
	last_frame_focused = focused

	// Handle modifers for key evets so that shortcuts work
	ctrl_down := is_control_down()
	if ctrl_down != last_control_pressed {
		im.IO_AddKeyEvent(io, im.Key.ImGuiMod_Ctrl, ctrl_down)
	}
	last_control_pressed = ctrl_down

	shift_down := is_shift_down()
	if shift_down != last_shift_pressed {
		im.IO_AddKeyEvent(io, im.Key.ImGuiMod_Shift, shift_down)
	}
	last_shift_pressed = shift_down

	alt_down := is_alt_down()
	if alt_down != last_alt_pressed {
		im.IO_AddKeyEvent(io, im.Key.ImGuiMod_Alt, alt_down)
	}
	last_alt_pressed = alt_down

	super_down := is_super_down()
	if super_down != last_super_pressed {
		im.IO_AddKeyEvent(io, im.Key.ImGuiMod_Super, super_down)
	}
	last_super_pressed = super_down

	// Get pressed keys, they are in event order
	key_id: rl.KeyboardKey = rl.GetKeyPressed()
	for key_id != rl.KeyboardKey.KEY_NULL {
		key, ok := raylib_key_map[key_id]
		if ok {
			im.IO_AddKeyEvent(io, key, true)
		}

		key_id = rl.GetKeyPressed()
	}

	// Check for released keys
	for key in raylib_key_map {
		if rl.IsKeyReleased(key) {
			im.IO_AddKeyEvent(io, raylib_key_map[key], false)
		}
	}

	// Add text input in order
	pressed: rune = rl.GetCharPressed()
	for pressed != 0 {
		im.IO_AddInputCharacter(io, u32(pressed))
		pressed = rl.GetCharPressed()
	}

	return true
}

@(private)
setup_globals :: proc() {
	last_frame_focused = rl.IsWindowFocused()
	last_control_pressed = false
	last_shift_pressed = false
	last_alt_pressed = false
	last_super_pressed = false
}

@(private)
setup_keymap :: proc() {
	raylib_key_map[rl.KeyboardKey.APOSTROPHE] = im.Key.Apostrophe
	raylib_key_map[rl.KeyboardKey.COMMA] = im.Key.Comma
	raylib_key_map[rl.KeyboardKey.MINUS] = im.Key.Minus
	raylib_key_map[rl.KeyboardKey.PERIOD] = im.Key.Period
	raylib_key_map[rl.KeyboardKey.SLASH] = im.Key.Slash
	raylib_key_map[rl.KeyboardKey.ZERO] = im.Key._0
	raylib_key_map[rl.KeyboardKey.ONE] = im.Key._1
	raylib_key_map[rl.KeyboardKey.TWO] = im.Key._2
	raylib_key_map[rl.KeyboardKey.THREE] = im.Key._3
	raylib_key_map[rl.KeyboardKey.FOUR] = im.Key._4
	raylib_key_map[rl.KeyboardKey.FIVE] = im.Key._5
	raylib_key_map[rl.KeyboardKey.SIX] = im.Key._6
	raylib_key_map[rl.KeyboardKey.SEVEN] = im.Key._7
	raylib_key_map[rl.KeyboardKey.EIGHT] = im.Key._8
	raylib_key_map[rl.KeyboardKey.NINE] = im.Key._9
	raylib_key_map[rl.KeyboardKey.SEMICOLON] = im.Key.Semicolon
	raylib_key_map[rl.KeyboardKey.EQUAL] = im.Key.Equal
	raylib_key_map[rl.KeyboardKey.A] = im.Key.A
	raylib_key_map[rl.KeyboardKey.B] = im.Key.B
	raylib_key_map[rl.KeyboardKey.C] = im.Key.C
	raylib_key_map[rl.KeyboardKey.D] = im.Key.D
	raylib_key_map[rl.KeyboardKey.E] = im.Key.E
	raylib_key_map[rl.KeyboardKey.F] = im.Key.F
	raylib_key_map[rl.KeyboardKey.G] = im.Key.G
	raylib_key_map[rl.KeyboardKey.H] = im.Key.H
	raylib_key_map[rl.KeyboardKey.I] = im.Key.I
	raylib_key_map[rl.KeyboardKey.J] = im.Key.J
	raylib_key_map[rl.KeyboardKey.K] = im.Key.K
	raylib_key_map[rl.KeyboardKey.L] = im.Key.L
	raylib_key_map[rl.KeyboardKey.M] = im.Key.M
	raylib_key_map[rl.KeyboardKey.N] = im.Key.N
	raylib_key_map[rl.KeyboardKey.O] = im.Key.O
	raylib_key_map[rl.KeyboardKey.P] = im.Key.P
	raylib_key_map[rl.KeyboardKey.Q] = im.Key.Q
	raylib_key_map[rl.KeyboardKey.R] = im.Key.R
	raylib_key_map[rl.KeyboardKey.S] = im.Key.S
	raylib_key_map[rl.KeyboardKey.T] = im.Key.T
	raylib_key_map[rl.KeyboardKey.U] = im.Key.U
	raylib_key_map[rl.KeyboardKey.V] = im.Key.V
	raylib_key_map[rl.KeyboardKey.W] = im.Key.W
	raylib_key_map[rl.KeyboardKey.X] = im.Key.X
	raylib_key_map[rl.KeyboardKey.Y] = im.Key.Y
	raylib_key_map[rl.KeyboardKey.Z] = im.Key.Z
	raylib_key_map[rl.KeyboardKey.SPACE] = im.Key.Space
	raylib_key_map[rl.KeyboardKey.ESCAPE] = im.Key.Escape
	raylib_key_map[rl.KeyboardKey.ENTER] = im.Key.Enter
	raylib_key_map[rl.KeyboardKey.TAB] = im.Key.Tab
	raylib_key_map[rl.KeyboardKey.BACKSPACE] = im.Key.Backspace
	raylib_key_map[rl.KeyboardKey.INSERT] = im.Key.Insert
	raylib_key_map[rl.KeyboardKey.DELETE] = im.Key.Delete
	raylib_key_map[rl.KeyboardKey.RIGHT] = im.Key.RightArrow
	raylib_key_map[rl.KeyboardKey.LEFT] = im.Key.LeftArrow
	raylib_key_map[rl.KeyboardKey.DOWN] = im.Key.DownArrow
	raylib_key_map[rl.KeyboardKey.UP] = im.Key.UpArrow
	raylib_key_map[rl.KeyboardKey.PAGE_UP] = im.Key.PageUp
	raylib_key_map[rl.KeyboardKey.PAGE_DOWN] = im.Key.PageDown
	raylib_key_map[rl.KeyboardKey.HOME] = im.Key.Home
	raylib_key_map[rl.KeyboardKey.END] = im.Key.End
	raylib_key_map[rl.KeyboardKey.CAPS_LOCK] = im.Key.CapsLock
	raylib_key_map[rl.KeyboardKey.SCROLL_LOCK] = im.Key.ScrollLock
	raylib_key_map[rl.KeyboardKey.NUM_LOCK] = im.Key.NumLock
	raylib_key_map[rl.KeyboardKey.PRINT_SCREEN] = im.Key.PrintScreen
	raylib_key_map[rl.KeyboardKey.PAUSE] = im.Key.Pause
	raylib_key_map[rl.KeyboardKey.F1] = im.Key.F1
	raylib_key_map[rl.KeyboardKey.F2] = im.Key.F2
	raylib_key_map[rl.KeyboardKey.F3] = im.Key.F3
	raylib_key_map[rl.KeyboardKey.F4] = im.Key.F4
	raylib_key_map[rl.KeyboardKey.F5] = im.Key.F5
	raylib_key_map[rl.KeyboardKey.F6] = im.Key.F6
	raylib_key_map[rl.KeyboardKey.F7] = im.Key.F7
	raylib_key_map[rl.KeyboardKey.F8] = im.Key.F8
	raylib_key_map[rl.KeyboardKey.F9] = im.Key.F9
	raylib_key_map[rl.KeyboardKey.F10] = im.Key.F10
	raylib_key_map[rl.KeyboardKey.F11] = im.Key.F11
	raylib_key_map[rl.KeyboardKey.F12] = im.Key.F12
	raylib_key_map[rl.KeyboardKey.LEFT_SHIFT] = im.Key.LeftShift
	raylib_key_map[rl.KeyboardKey.LEFT_CONTROL] = im.Key.LeftCtrl
	raylib_key_map[rl.KeyboardKey.LEFT_ALT] = im.Key.LeftAlt
	raylib_key_map[rl.KeyboardKey.LEFT_SUPER] = im.Key.LeftSuper
	raylib_key_map[rl.KeyboardKey.RIGHT_SHIFT] = im.Key.RightShift
	raylib_key_map[rl.KeyboardKey.RIGHT_CONTROL] = im.Key.RightCtrl
	raylib_key_map[rl.KeyboardKey.RIGHT_ALT] = im.Key.RightAlt
	raylib_key_map[rl.KeyboardKey.RIGHT_SUPER] = im.Key.RightSuper
	raylib_key_map[rl.KeyboardKey.KB_MENU] = im.Key.Menu
	raylib_key_map[rl.KeyboardKey.LEFT_BRACKET] = im.Key.LeftBracket
	raylib_key_map[rl.KeyboardKey.BACKSLASH] = im.Key.Backslash
	raylib_key_map[rl.KeyboardKey.RIGHT_BRACKET] = im.Key.RightBracket
	raylib_key_map[rl.KeyboardKey.GRAVE] = im.Key.GraveAccent
	raylib_key_map[rl.KeyboardKey.KP_0] = im.Key.Keypad0
	raylib_key_map[rl.KeyboardKey.KP_1] = im.Key.Keypad1
	raylib_key_map[rl.KeyboardKey.KP_2] = im.Key.Keypad2
	raylib_key_map[rl.KeyboardKey.KP_3] = im.Key.Keypad3
	raylib_key_map[rl.KeyboardKey.KP_4] = im.Key.Keypad4
	raylib_key_map[rl.KeyboardKey.KP_5] = im.Key.Keypad5
	raylib_key_map[rl.KeyboardKey.KP_6] = im.Key.Keypad6
	raylib_key_map[rl.KeyboardKey.KP_7] = im.Key.Keypad7
	raylib_key_map[rl.KeyboardKey.KP_8] = im.Key.Keypad8
	raylib_key_map[rl.KeyboardKey.KP_9] = im.Key.Keypad9
	raylib_key_map[rl.KeyboardKey.KP_DECIMAL] = im.Key.KeypadDecimal
	raylib_key_map[rl.KeyboardKey.KP_DIVIDE] = im.Key.KeypadDivide
	raylib_key_map[rl.KeyboardKey.KP_MULTIPLY] = im.Key.KeypadMultiply
	raylib_key_map[rl.KeyboardKey.KP_SUBTRACT] = im.Key.KeypadSubtract
	raylib_key_map[rl.KeyboardKey.KP_ADD] = im.Key.KeypadAdd
	raylib_key_map[rl.KeyboardKey.KP_ENTER] = im.Key.KeypadEnter
	raylib_key_map[rl.KeyboardKey.KP_EQUAL] = im.Key.KeypadEqual
}

@(private)
setup_mouse_cursor :: proc() {
	mouse_cursor_map[im.MouseCursor.Arrow] = rl.MouseCursor.ARROW
	mouse_cursor_map[im.MouseCursor.TextInput] = rl.MouseCursor.IBEAM
	mouse_cursor_map[im.MouseCursor.Hand] = rl.MouseCursor.POINTING_HAND
	mouse_cursor_map[im.MouseCursor.ResizeAll] = rl.MouseCursor.RESIZE_ALL
	mouse_cursor_map[im.MouseCursor.ResizeEW] = rl.MouseCursor.RESIZE_EW
	mouse_cursor_map[im.MouseCursor.ResizeNESW] = rl.MouseCursor.RESIZE_NESW
	mouse_cursor_map[im.MouseCursor.ResizeNS] = rl.MouseCursor.RESIZE_NS
	mouse_cursor_map[im.MouseCursor.ResizeNWSE] = rl.MouseCursor.RESIZE_NWSE
	mouse_cursor_map[im.MouseCursor.NotAllowed] = rl.MouseCursor.NOT_ALLOWED
}

@(private)
setup_backend :: proc() {
	io: ^im.IO = im.GetIO()
	io.BackendPlatformName = "imgui_impl_raylib"

	io.BackendFlags |= {im.BackendFlag.HasMouseCursors}

	io.MousePos = {0, 0}

	io.SetClipboardTextFn = set_clip_text_callback
	io.GetClipboardTextFn = get_clip_text_callback

	io.ClipboardUserData = nil
}

@(private)
set_clip_text_callback :: proc "c" (user_data: rawptr, text: cstring) {
	rl.SetClipboardText(text)
}

@(private)
get_clip_text_callback :: proc "c" (user_data: rawptr) -> cstring {
	return rl.GetClipboardText()
}
