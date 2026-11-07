package tyr

set :: struct($T: typeid) {
	elements: map[T]struct{},
}

set_make :: proc($T: typeid) -> set(T) {
	return set(T){elements = make(map[T]struct{})}
}

set_delete :: proc(self: ^set) {
	delete_map(self.elements)
}

set_add :: proc(self: ^set, value: $T) {
	self.elements[value] = {}
}

set_remove :: proc(self: ^set, value: $T) {
	delete_key(&self.elements, value)
}

set_contains :: proc(self: ^set, value:$T) -> bool {
	_, exists := self.elements[value]
	return exists
}

set_clear :: proc(self: ^set) {
    clear(&self.elements)
}

set_is_empty :: proc(self: ^set) -> bool {
    return len(self.elements) == 0
}

set_len :: proc(self: ^set) -> int {
    return len(self.elements)
}

set_union :: proc(a, b: set($T)) -> set(T) {
    result := set_make(T)

    for value in a.elements {
        result.elements[value] = {}
    }

    for value in b.elements {
        result.elements[value] = {}
    }

    return result
}

set_intersection :: proc(a, b: set($T)) -> set(T) {
    result := set_make(T)

    for value in a.elements {
        if set_contains(b, value) {
            result.elements[value] = {}
        }
    }

    return result
}

set_difference :: proc(a, b: set($T)) -> set(T) {
    result := set_make(T)

    for value in a.elements {
        if !set_contains(b, value) {
            result.elements[value] = {}
        }
    }

    return result
}

set_symmetric_difference :: proc(a, b: set($T)) -> set(T) {
    result := set_make(T)

    for value in a.elements {
        if !set_contains(b, value) {
            result.elements[value] = {}
        }
    }

    for value in b.elements {
        if !set_contains(a, value) {
            result.elements[value] = {}
        }
    }

    return result
}

set_is_subset :: proc(a, b: set($T)) -> bool {
    for value in a.elements {
        if !set_contains(b, value) {
            return false
        }
    }

    return true
}

set_is_superset :: proc(a, b: set($T)) -> bool {
    return set_is_subset(b, a)
}

set_is_disjoint :: proc(a, b: set($T)) -> bool {
    for value in a.elements {
        if set_contains(b, value) {
            return false
        }
    }

    return true
}

set_equals :: proc(a, b: set($T)) -> bool {
    return set_len(a) == set_len(b) && set_is_subset(a, b)
}

set_copy :: proc(self: set($T)) -> set(T) {
    result := set_make(T)

    for value in self.elements {
        result.elements[value] = {}
    }

    return result
}

set_add_all :: proc(self: ^set($T), other: set(T)) {
    for value in other.elements {
        self.elements[value] = {}
    }
}

set_remove_all :: proc(self: ^set($T), other: set(T)) {
    for value in other.elements {
        delete_key(&self.elements, value)
    }
}

set_retain_all :: proc(self: ^set($T), other: set(T)) {
    for value in self.elements {
        if !set_contains(other, value) {
            delete_key(&self.elements, value)
        }
    }
}
