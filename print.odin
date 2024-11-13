package tyr

import "core:fmt"

print :: proc(args: ..any, sep := " ", flush := true) -> int {
    return fmt.print(..args, sep=sep, flush=flush)
}

println :: proc(args: ..any, sep := " ", flush := true) -> int {
    return fmt.println(..args, sep=sep, flush=flush)
}