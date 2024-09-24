package tyr

ui_window_flags :: bit_set[ui_window_flag]
ui_window_flag :: enum {
	no_title_bar                = 0, // disable title-bar
	no_resize                   = 1, // disable user resizing with the lower-right grip
	no_move                     = 2, // disable user moving the window
	no_scrollbar                = 3, // disable scrollbars (window can still scroll with mouse or programmatically)
	no_scroll_with_mouse        = 4, // disable user vertically scrolling with mouse wheel. on child window, mouse wheel will be forwarded to the parent unless noscrollbar is also set.
	no_collapse                 = 5, // disable user collapsing window by double-clicking on it. also referred to as window menu button (e.g. within a docking node).
	always_auto_resize          = 6, // resize every window to its content every frame
	no_background               = 7, // disable drawing background color (windowbg, etc.) and outside border. similar as using setnextwindowbgalpha(0.0f).
	no_saved_settings           = 8, // never load/save settings in .ini file
	no_mouse_inputs             = 9, // disable catching mouse, hovering test with pass through.
	menu_bar                    = 10, // has a menu-bar
	horizontal_scrollbar        = 11, // allow horizontal scrollbar to appear (off by default). you may use setnextwindowcontentsize(imvec2(width,0.0f)); prior to calling begin() to specify width. read code in imgui_demo in the "horizontal scrolling" section.
	no_focus_on_appearing       = 12, // disable taking focus when transitioning from hidden to visible state
	no_bring_to_front_on_focus  = 13, // disable bringing window to front when taking focus (e.g. clicking on it or programmatically giving it focus)
	always_vertical_scrollbar   = 14, // always show vertical scrollbar (even if contentsize.y < size.y)
	always_horizontal_scrollbar = 15, // always show horizontal scrollbar (even if contentsize.x < size.x)
	no_nav_inputs               = 16, // no gamepad/keyboard navigation within the window
	no_nav_focus                = 17, // no focusing toward this window with gamepad/keyboard navigation (e.g. skipped by ctrl+tab)
	unsaved_document            = 18, // display a dot next to the title. when used in a tab/docking context, tab is selected when clicking the x + closure is not assumed (will wait for user to stop submitting the tab). otherwise closure is assumed when pressing the x, so if you keep submitting the tab may reappear at end of tab bar.
	no_docking                  = 19, // disable docking of this window
	// [internal]
	child_window                = 24, // don't use! for internal use by beginchild()
	tooltip                     = 25, // don't use! for internal use by begintooltip()
	popup                       = 26, // don't use! for internal use by beginpopup()
	modal                       = 27, // don't use! for internal use by beginpopupmodal()
	child_menu                  = 28, // don't use! for internal use by beginmenu()
	dock_node_host              = 29, // don't use! for internal use by begin()/newframe()
	always_use_window_padding   = 30, // obsoleted in 1.90.0: use imguichildflags_alwaysusewindowpadding in beginchild() call.
	nav_flattened               = 31, // obsoleted in 1.90.9: use imguichildflags_navflattened in beginchild() call.
}

ui_selectable_flags :: bit_set[ui_selectable_flag]
ui_selectable_flag :: enum {
	no_auto_close_popups = 0, // clicking this doesn't close parent popup window (overrides imguiitemflags_autoclosepopups)
	span_all_columns     = 1, // frame will span all columns of its container table (text will still fit in current column)
	allow_double_click   = 2, // generate press events on double clicks too
	disabled             = 3, // cannot be selected, display grayed out text
	allow_overlap        = 4, // (wip) hit testing to allow subsequent widgets to overlap this one
	highlight            = 5, // make the item be displayed as if it is hovered
}

ui_color_edit_flags :: bit_set[ui_color_edit_flag]
ui_color_edit_flag :: enum {
	no_alpha        = 1,  //              // coloredit, colorpicker, colorbutton: ignore alpha component (will only read 3 components from the input pointer).
	no_picker       = 2,  //              // coloredit: disable picker when clicking on color square.
	no_options      = 3,  //              // coloredit: disable toggling options menu when right-clicking on inputs/small preview.
	no_small_preview = 4,  //              // coloredit, colorpicker: disable color square preview next to the inputs. (e.g. to show only the inputs)
	no_inputs       = 5,  //              // coloredit, colorpicker: disable inputs sliders/text widgets (e.g. to show only the small preview color square).
	no_tooltip      = 6,  //              // coloredit, colorpicker, colorbutton: disable tooltip when hovering the preview.
	no_label        = 7,  //              // coloredit, colorpicker: disable display of inline text label (the label is still forwarded to the tooltip and picker).
	no_side_preview  = 8,  //              // colorpicker: disable bigger color preview on right side of the picker, use small color square preview instead.
	no_drag_drop     = 9,  //              // coloredit: disable drag and drop target. colorbutton: disable drag and drop source.
	no_border       = 10, //              // colorbutton: disable border (which is enforced by default)
	// user options (right-click on widget to change some of them).
	alpha_bar         = 16, //              // coloredit, colorpicker: show vertical alpha bar/gradient in picker.
	alpha_preview     = 17, //              // coloredit, colorpicker, colorbutton: display preview as a transparent color over a checkerboard, instead of opaque.
	alpha_preview_half = 18, //              // coloredit, colorpicker, colorbutton: display half opaque / half checkerboard, instead of opaque.
	hdr              = 19, //              // (wip) coloredit: currently only disable 0.0f..1.0f limits in rgba edition (note: you probably want to use imguicoloreditflags_float flag as well).
	display_rgb       = 20, // [display]    // coloredit: override _display_ type among rgb/hsv/hex. colorpicker: select any combination using one or more of rgb/hsv/hex.
	display_hsv       = 21, // [display]    // "
	display_hex       = 22, // [display]    // "
	uint8            = 23, // [datatype]   // coloredit, colorpicker, colorbutton: _display_ values formatted as 0..255.
	float            = 24, // [datatype]   // coloredit, colorpicker, colorbutton: _display_ values formatted as 0.0f..1.0f floats instead of 0..255 integers. no round-trip of value via integers.
	picker_hue_bar     = 25, // [picker]     // colorpicker: bar for hue, rectangle for sat/value.
	picker_hue_wheel   = 26, // [picker]     // colorpicker: wheel for hue, triangle for sat/value.
	input_rgb         = 27, // [input]      // coloredit, colorpicker: input and output data in rgb format.
	input_hsv         = 28, // [input]      // coloredit, colorpicker: input and output data in hsv format.
}

ui_slider_flags :: bit_set[ui_slider_flag]
ui_slider_flag :: enum {
	always_clamp     = 4, // clamp value to min/max bounds when input manually with ctrl+click. by default ctrl+click allows going out of bounds.
	logarithmic     = 5, // make the widget logarithmic (linear otherwise). consider using imguisliderflags_noroundtoformat with this if using a format-string with small amount of digits.
	no_round_to_format = 6, // disable rounding underlying value to match precision of the display format string (e.g. %.3f values are rounded to those 3 digits).
	no_input         = 7, // disable ctrl+click or enter key allowing to input text directly into the widget.
	wrap_around      = 8, // enable wrapping around from max to min and from min to max (only supported by dragxxx() functions for now.
}

ui_dock_node_flags :: bit_set[ui_dock_node_flag]
ui_dock_node_flag :: enum {
	keep_alive_only = 0, //       // don't display the dockspace node but keep it alive. windows docked into this dockspace node won't be undocked.
	//imguidocknodeflags_nocentralnode              = 1 << 1,   //       // disable central node (the node which can stay empty)
	no_docking_over_central_node = 2, //       // disable docking over the central node, which will be always kept empty.
	passthru_central_node      = 3, //       // enable passthru dockspace: 1) dockspace() will render a imguicol_windowbg background covering everything excepted the central node when empty. meaning the host window should probably use setnextwindowbgalpha(0.0f) prior to begin() when using this. 2) when central node is empty: let inputs pass-through + won't display a dockingemptybg background. see demo for details.
	no_docking_split           = 4, //       // disable other windows/nodes from splitting this node.
	no_resize                 = 5, // saved // disable resizing node using the splitter/separators. useful with programmatically setup dockspaces.
	auto_hide_tab_bar           = 6, //       // tab bar will automatically hide when there is a single window in the dock node.
	no_undocking              = 7, //       // disable undocking this node.
}

ui_input_text_flags :: bit_set[ui_input_text_flag]
ui_input_text_flag :: enum {
	chars_decimal     = 0, // allow 0123456789.+-*/
	chars_hexadecimal = 1, // allow 0123456789abcdefabcdef
	chars_scientific  = 2, // allow 0123456789.+-*/ee (scientific notation input)
	chars_uppercase   = 3, // turn a..z into a..z
	chars_noblank     = 4, // filter out spaces, tabs
	// inputs
	allow_tab_input       = 5, // pressing tab input a '\t' character into the text field
	enter_returns_true    = 6, // return 'true' when enter is pressed (as opposed to every time the value was modified). consider looking at the isitemdeactivatedafteredit() function.
	escape_clears_all     = 7, // escape key clears content if not empty, and deactivate otherwise (contrast to default behavior of escape to revert)
	ctrl_enter_for_new_line = 8, // in multi-line mode, validate with enter, add new line with ctrl+enter (default is opposite: validate with ctrl+enter, add line with enter).
	// other options
	read_only           = 9,  // read-only mode
	password           = 10, // password mode, display all characters as '*', disable copy
	always_overwrite    = 11, // overwrite mode
	auto_select_all      = 12, // select entire text when first taking mouse focus
	parse_empty_ref_val   = 13, // inputfloat(), inputint(), inputscalar() etc. only: parse empty string as zero value.
	display_empty_ref_val = 14, // inputfloat(), inputint(), inputscalar() etc. only: when value is zero, do not display it. generally used with imguiinputtextflags_parseemptyrefval.
	no_horizontal_scroll = 15, // disable following the cursor horizontally
	no_undo_redo         = 16, // disable undo/redo. note that input text owns the text data while active, if you want to provide your own undo/redo stack you need e.g. to call clearactiveid().
	// callback features
	callback_completion = 17, // callback on pressing tab (for completion handling)
	callback_history    = 18, // callback on pressing up/down arrows (for history handling)
	callback_always     = 19, // callback on each iteration. user code may query cursor position, modify text buffer.
	callback_char_filter = 20, // callback on character inputs to replace or discard them. modify 'eventchar' to replace or discard, or return 1 in callback to discard.
	callback_resize     = 21, // callback on buffer capacity changes request (beyond 'buf_size' parameter value), allowing the string to grow. notify when the string wants to be resized (for string types which hold a cache of their size). you will be provided a new bufsize in the callback and need to honor it. (see misc/cpp/imgui_stdlib.h for an example of using this)
	callback_edit       = 22, // callback on any edit (note that inputtext() already returns true on edit, the callback is useful mainly to manipulate the underlying buffer while focus is active)
}

ui :: struct {
	data:         rawptr,
	begin_window: proc(data: rawptr, name: string, open: ^bool, flags: ui_window_flags) -> bool,
	end_window:   proc(data: rawptr),
	button:       proc(data: rawptr, label: string) -> bool,
	selectable:   proc(
		data: rawptr,
		label: string,
		selected: bool = false,
		flags: ui_selectable_flags = {},
		size: vec2,
	) -> bool,
	tree_node: proc(data: rawptr, label: string) -> bool,
	tree_pop:  proc(data: rawptr),
	color_edit_4 : proc(data: rawptr, label: string, col: ^[4]fp, flags: ui_color_edit_flags = {}) -> bool,
	drag_int : proc(data: rawptr, label: string, v: ^i32, v_speed: f32 = 1, v_min: i32 = 0, v_max: i32 = 0, format: string = "%d", flags: ui_slider_flags = {}) -> bool,
	drag_int3 : proc(data: rawptr, label: string, v: ^[3]i32, v_speed: f32 = 1, v_min: i32 = 0, v_max: i32 = 0, format: string = "%d", flags: ui_slider_flags = {}) -> bool,
	drag_float : proc(data: rawptr, label: string, v: ^fp, v_speed: fp = 1.0, v_min: fp = 0.0, v_max: fp = 0.0, format: string = "%.3f", flags: ui_slider_flags = {}) -> bool,
	drag_float3 : proc(data: rawptr, label: string, v: ^[3]fp, v_speed: fp = 1.0, v_min: fp = 0.0, v_max: fp = 0.0, format: string = "%.3f", flags: ui_slider_flags = {}) -> bool,
	dockspace_over_viewport : proc(data: rawptr, id: string, flags: ui_dock_node_flags = {}),
	input_text : proc(data: rawptr, label: string, buf: ^string, flags: ui_input_text_flags = {}) -> bool
	
}

ui_begin_window :: proc(
	ui: ^ui,
	name: string,
	open: ^bool = nil,
	flags: ui_window_flags = {},
) -> bool {
	return ui.begin_window(ui.data, name, open, flags)
}

ui_end_window :: proc(ui: ^ui) {
	ui.end_window(ui.data)
}

ui_button :: proc(ui: ^ui, label: string) -> bool {
	return ui.button(ui.data, label)
}

ui_selectable :: proc(
	ui: ^ui,
	label: string,
	selected: bool = false,
	flags: ui_selectable_flags = {},
	size: vec2 = {0, 0},
) -> bool {
	return ui.selectable(ui.data, label, selected, flags, size)
}

ui_tree_node :: proc(ui: ^ui, label: string) -> bool {
	return ui.tree_node(ui.data, label)
}

ui_tree_pop :: proc(ui: ^ui) {
	ui.tree_pop(ui.data)
}

ui_color_edit_4 :: proc(ui: ^ui, label: string, col: ^[4]fp, flags: ui_color_edit_flags = {}) -> bool {
	return ui.color_edit_4(ui.data, label, col, flags)
}

ui_drag_int :: proc(ui: ^ui, label: string, v: ^i32, v_speed: f32 = 1, v_min: i32 = 0, v_max: i32 = 0, format: string = "%d", flags: ui_slider_flags = {}) -> bool {
	return ui.drag_int(ui.data, label, v, v_speed, v_min, v_max, format, flags)
}

ui_drag_int3 :: proc(ui: ^ui, label: string, v: ^[3]i32, v_speed: f32 = 1, v_min: i32 = 0, v_max: i32 = 0, format: string = "%d", flags: ui_slider_flags = {}) -> bool {
	return ui.drag_int3(ui.data, label, v, v_speed, v_min, v_max, format, flags)
}

ui_drag_float :: proc(ui: ^ui, label: string, v: ^fp, v_speed: fp = 1.0, v_min: fp = 0.0, v_max: fp = 0.0, format: string = "%.3f", flags: ui_slider_flags = {}) -> bool {
	return ui.drag_float(ui.data, label, v, v_speed, v_min, v_max, format, flags)
}

ui_drag_float3 :: proc(ui: ^ui, label: string, v: ^[3]fp, v_speed: fp = 1.0, v_min: fp = 0.0, v_max: fp = 0.0, format: string = "%.3f", flags: ui_slider_flags = {}) -> bool {
	return ui.drag_float3(ui.data, label, v, v_speed, v_min, v_max, format, flags)
}

ui_step :: struct {
	using step: app_step,
	ui:         ^ui,
}

ui_plugin :: proc(app: ^app) {
	app_add_plugins(app, imgui_plugin)
	app_set_resource(app, imgui_ui())
	app_add_systems(app, imgui_step, ui_update_system)
}

ui_update_system :: proc(#by_ptr step: imgui_step) {
	ui, ok := resources_get(step.resources, ui)
	if !ok {
		return
	}
	scheduler_dispatch(step.scheduler, ui_step, ui_step{step = step, ui = ui})
}

ui_dockspace_over_viewport :: proc(ui: ^ui, id: string, flags: ui_dock_node_flags = {}) {
	ui.dockspace_over_viewport(ui.data, id, flags)
}

ui_input_text :: proc(ui: ^ui, label: string, buf: ^string, flags: ui_input_text_flags = {}) -> bool {
	return ui.input_text(ui.data, label, buf, flags)
}
