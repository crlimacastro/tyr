package tyr

import "base:runtime"
import "core:fmt"

@(disabled = ODIN_DISABLE_ASSERT)
assertf :: proc(
	condition: bool,
	fmt_message := #caller_expression(condition),
	args: ..any,
	loc := #caller_location,
) {
	if !condition {
		// NOTE(bill): This is wrapped in a procedure call
		// to improve performance to make the CPU not
		// execute speculatively, making it about an order of
		// magnitude faster
		@(cold)
		internal :: proc(
			condition: bool,
			fmt_message: string,
			loc: runtime.Source_Code_Location,
			args: ..any,
		) {
			assert(condition, fmt.tprintf(fmt_message, ..args), loc=loc)
		}
		internal(condition, fmt_message, loc, ..args)
	}
}
