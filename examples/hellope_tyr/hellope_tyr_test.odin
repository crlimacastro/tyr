package hellope_tyr

import "core:testing"

@(test)
base_test :: proc(t: ^testing.T) {
    testing.expect(t, 1 + 1 == 2, "1 + 1 failed to equal 2.")
}
