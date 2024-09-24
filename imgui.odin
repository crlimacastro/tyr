package tyr

import "core:strings"
import imrl "imgui_raylib_impl"
import im "odin-imgui"

cstring_buffers_length :: 1024

ui_window_flag_to_im_window_flag := map[ui_window_flag]im.WindowFlag {
	.no_title_bar                = .NoTitleBar,
	.no_resize                   = .NoResize,
	.no_move                     = .NoMove,
	.no_scrollbar                = .NoScrollbar,
	.no_scroll_with_mouse        = .NoScrollWithMouse,
	.no_collapse                 = .NoCollapse,
	.always_auto_resize          = .AlwaysAutoResize,
	.no_background               = .NoBackground,
	.no_saved_settings           = .NoSavedSettings,
	.no_mouse_inputs             = .NoMouseInputs,
	.menu_bar                    = .MenuBar,
	.horizontal_scrollbar        = .HorizontalScrollbar,
	.no_focus_on_appearing       = .NoFocusOnAppearing,
	.no_bring_to_front_on_focus  = .NoBringToFrontOnFocus,
	.always_vertical_scrollbar   = .AlwaysVerticalScrollbar,
	.always_horizontal_scrollbar = .AlwaysHorizontalScrollbar,
	.no_nav_inputs               = .NoNavInputs,
	.no_nav_focus                = .NoNavFocus,
	.unsaved_document            = .UnsavedDocument,
	.no_docking                  = .NoDocking,
	.child_window                = .ChildWindow,
	.tooltip                     = .Tooltip,
	.popup                       = .Popup,
	.modal                       = .Modal,
	.child_menu                  = .ChildMenu,
	.dock_node_host              = .DockNodeHost,
	.always_use_window_padding   = .AlwaysUseWindowPadding,
	.nav_flattened               = .NavFlattened,
}

imgui_ui_window_flags_to_im_window_flags :: proc(flags: ui_window_flags) -> im.WindowFlags {
	im_flags: im.WindowFlags

	for flag in flags {
		im_flags += {ui_window_flag_to_im_window_flag[flag]}
	}
	return im_flags
}

ui_selectable_flag_to_im_selectable_flag := map[ui_selectable_flag]im.SelectableFlag {
	.no_auto_close_popups = .NoAutoClosePopups,
	.span_all_columns     = .SpanAllColumns,
	.allow_double_click   = .AllowDoubleClick,
	.disabled             = .Disabled,
	.allow_overlap        = .AllowOverlap,
	.highlight            = .Highlight,
}

imgui_ui_selectable_flags_to_im_selectable_flags :: proc(
	flags: ui_selectable_flags,
) -> im.SelectableFlags {
	im_flags: im.SelectableFlags

	for flag in flags {
		im_flags += {ui_selectable_flag_to_im_selectable_flag[flag]}
	}
	return im_flags
}

ui_color_flag_to_im_color_edit_flag := map[ui_color_edit_flag]im.ColorEditFlag {
	.no_alpha           = .NoAlpha,
	.no_picker          = .NoPicker,
	.no_options         = .NoOptions,
	.no_small_preview   = .NoSmallPreview,
	.no_inputs          = .NoInputs,
	.no_tooltip         = .NoTooltip,
	.no_label           = .NoLabel,
	.no_side_preview    = .NoSidePreview,
	.no_drag_drop       = .NoDragDrop,
	.no_border          = .NoBorder,
	.alpha_bar          = .AlphaBar,
	.alpha_preview      = .AlphaPreview,
	.alpha_preview_half = .AlphaPreviewHalf,
	.hdr                = .HDR,
	.display_rgb        = .DisplayRGB,
	.display_hsv        = .DisplayHSV,
	.display_hex        = .DisplayHex,
	.uint8              = .Uint8,
	.float              = .Float,
	.picker_hue_bar     = .PickerHueBar,
	.picker_hue_wheel   = .PickerHueWheel,
	.input_rgb          = .InputRGB,
	.input_hsv          = .InputHSV,
}

imgui_ui_color_edit_flags_to_im_color_edit_flags :: proc(
	flags: ui_color_edit_flags,
) -> im.ColorEditFlags {
	im_flags: im.ColorEditFlags

	for flag in flags {
		im_flags += {ui_color_flag_to_im_color_edit_flag[flag]}
	}
	return im_flags
}

ui_slider_flags_to_im_slider_flag := map[ui_slider_flag]im.SliderFlag {
	.always_clamp       = .AlwaysClamp,
	.logarithmic        = .Logarithmic,
	.no_round_to_format = .NoRoundToFormat,
	.wrap_around        = .WrapAround,
}

imgui_ui_slider_flags_to_im_slider_flags :: proc(flags: ui_slider_flags) -> im.SliderFlags {
	im_flags: im.SliderFlags

	for flag in flags {
		im_flags += {ui_slider_flags_to_im_slider_flag[flag]}
	}
	return im_flags
}

ui_dock_node_flag_to_im_dock_node_flag := map[ui_dock_node_flag]im.DockNodeFlag {
	.keep_alive_only              = .KeepAliveOnly,
	.no_docking_over_central_node = .NoDockingOverCentralNode,
	.passthru_central_node        = .PassthruCentralNode,
	.no_docking_split             = .NoDockingSplit,
	.no_resize                    = .NoResize,
	.auto_hide_tab_bar            = .AutoHideTabBar,
	.no_undocking                 = .NoUndocking,
}

imgui_dock_node_flags_to_im_dock_node_flags :: proc(
	flags: ui_dock_node_flags,
) -> im.DockNodeFlags {
	im_flags: im.DockNodeFlags

	for flag in flags {
		im_flags += {ui_dock_node_flag_to_im_dock_node_flag[flag]}
	}
	return im_flags
}

ui_input_text_flag_to_im_input_text_flag := map[ui_input_text_flag]im.InputTextFlag {
	.chars_decimal           = .CharsDecimal,
	.chars_hexadecimal       = .CharsHexadecimal,
	.chars_scientific        = .CharsScientific,
	.chars_uppercase         = .CharsUppercase,
	.chars_noblank           = .CharsNoBlank,
	.allow_tab_input         = .AllowTabInput,
	.enter_returns_true      = .EnterReturnsTrue,
	.escape_clears_all       = .EscapeClearsAll,
	.ctrl_enter_for_new_line = .CtrlEnterForNewLine,
	.read_only               = .ReadOnly,
	.password                = .Password,
	.always_overwrite        = .AlwaysOverwrite,
	.auto_select_all         = .AutoSelectAll,
	.parse_empty_ref_val     = .ParseEmptyRefVal,
	.display_empty_ref_val   = .DisplayEmptyRefVal,
	.no_horizontal_scroll    = .NoHorizontalScroll,
	.no_undo_redo            = .NoUndoRedo,
	.callback_completion     = .CallbackCompletion,
	.callback_history        = .CallbackHistory,
	.callback_always         = .CallbackAlways,
	.callback_char_filter    = .CallbackCharFilter,
	.callback_resize         = .CallbackResize,
	.callback_edit           = .CallbackEdit,
}

imgui_ui_input_text_flags_to_im_input_text_flags :: proc(
	flags: ui_input_text_flags,
) -> im.InputTextFlags {
	im_flags: im.InputTextFlags

	for flag in flags {
		im_flags += {ui_input_text_flag_to_im_input_text_flag[flag]}
	}
	return im_flags
}

imgui_ui :: proc() -> ui {
	return {
		data = {},
		begin_window = proc(
			data: rawptr,
			name: string,
			open: ^bool,
			flags: ui_window_flags,
		) -> bool {
			name_cstr := strings.clone_to_cstring(name, context.temp_allocator)
			return im.Begin(name_cstr, open, imgui_ui_window_flags_to_im_window_flags(flags))
		},
		end_window = proc(data: rawptr) {
			im.End()
		},
		button = proc(data: rawptr, label: string) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			return im.Button(label_cstr)
		},
		selectable = proc(
			data: rawptr,
			label: string,
			selected: bool = false,
			flags: ui_selectable_flags = {},
			size: vec2,
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			return im.Selectable(
				label_cstr,
				selected,
				imgui_ui_selectable_flags_to_im_selectable_flags(flags),
				size,
			)
		},
		tree_node = proc(data: rawptr, label: string) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			return im.TreeNode(label_cstr)
		},
		tree_pop = proc(data: rawptr) {
			im.TreePop()
		},
		color_edit_4 = proc(
			data: rawptr,
			label: string,
			col: ^[4]fp,
			flags: ui_color_edit_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			return im.ColorEdit4(
				label_cstr,
				col,
				imgui_ui_color_edit_flags_to_im_color_edit_flags(flags),
			)
		},
		drag_int = proc(
			data: rawptr,
			label: string,
			v: ^i32,
			v_speed: f32 = 1,
			v_min: i32 = 0,
			v_max: i32 = 0,
			format: string = "%d",
			flags: ui_slider_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			format_cstr := strings.clone_to_cstring(format, context.temp_allocator)
			return im.DragInt(
				label_cstr,
				v,
				v_speed,
				v_min,
				v_max,
				format_cstr,
				imgui_ui_slider_flags_to_im_slider_flags(flags),
			)
		},
		drag_int3 = proc(
			data: rawptr,
			label: string,
			v: ^[3]i32,
			v_speed: f32 = 1,
			v_min: i32 = 0,
			v_max: i32 = 0,
			format: string = "%d",
			flags: ui_slider_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			format_cstr := strings.clone_to_cstring(format, context.temp_allocator)
			return im.DragInt3(
				label_cstr,
				v,
				v_speed,
				v_min,
				v_max,
				format_cstr,
				imgui_ui_slider_flags_to_im_slider_flags(flags),
			)
		},
		drag_float = proc(
			data: rawptr,
			label: string,
			v: ^fp,
			v_speed: fp = 1.0,
			v_min: fp = 0.0,
			v_max: fp = 0.0,
			format: string = "%.3f",
			flags: ui_slider_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			format_cstr := strings.clone_to_cstring(format, context.temp_allocator)
			return im.DragFloat(
				label_cstr,
				v,
				v_speed,
				v_min,
				v_max,
				format_cstr,
				imgui_ui_slider_flags_to_im_slider_flags(flags),
			)
		},
		drag_float3 = proc(
			data: rawptr,
			label: string,
			v: ^[3]fp,
			v_speed: fp = 1.0,
			v_min: fp = 0.0,
			v_max: fp = 0.0,
			format: string = "%.3f",
			flags: ui_slider_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			format_cstr := strings.clone_to_cstring(format, context.temp_allocator)
			return im.DragFloat3(
				label_cstr,
				v,
				v_speed,
				v_min,
				v_max,
				format_cstr,
				imgui_ui_slider_flags_to_im_slider_flags(flags),
			)
		},
		dockspace_over_viewport = proc(data: rawptr, id: string, flags: ui_dock_node_flags = {}) {
			id_cstr := strings.clone_to_cstring(id, context.temp_allocator)
			im.DockSpaceOverViewport(
				im.GetID(id_cstr),
				{},
				imgui_dock_node_flags_to_im_dock_node_flags(flags),
			)
		},
		input_text = proc(
			data: rawptr,
			label: string,
			buf: ^string,
			flags: ui_input_text_flags = {},
		) -> bool {
			label_cstr := strings.clone_to_cstring(label, context.temp_allocator)
			buf_cstr := strings.clone_to_cstring(buf^, context.temp_allocator)
			ret := im.InputText(
				label_cstr,
				buf_cstr,
				cstring_buffers_length,
				imgui_ui_input_text_flags_to_im_input_text_flags(flags),
			)
			if ret {
				buf^ = strings.clone_from_cstring(buf_cstr)
			}
			return ret
		},
	}
}

imgui_step :: struct {
	using step: app_step,
}

imgui_plugin :: proc(app: ^app) {
	im.CHECKVERSION()
	im.CreateContext()

	io := im.GetIO()
	io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad, .DockingEnable, .ViewportsEnable}
	style := im.GetStyle()
	style.WindowRounding = 0
	style.Colors[im.Col.WindowBg].w = 1
	im.StyleColorsDark()

	imrl.init()
	imrl.build_font_atlas()

	app_add_systems(app, rendering_step, imgui_update_system)
	app_add_systems(app, deinit_step, imgui_deinit_system)
}

imgui_update_system :: proc(#by_ptr step: rendering_step) {
	imrl.process_events()
	imrl.new_frame()
	im.NewFrame()
	scheduler_dispatch(step.scheduler, imgui_step, imgui_step{step = step})
	im.Render()
	imrl.render_draw_data(im.GetDrawData())
	im.UpdatePlatformWindows()
	im.RenderPlatformWindowsDefault()
}

imgui_deinit_system :: proc(#by_ptr step: deinit_step) {
	imrl.shutdown()
	im.DestroyContext()
}
