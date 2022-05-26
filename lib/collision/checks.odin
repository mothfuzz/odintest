package collision

import "core:math"

test :: proc(a: ^Collider, b: ^Collider) -> bool {
	if a == b {
		return false
	}
	amax := a.max + a.t.position
	amin := a.min + a.t.position
	bmax := b.max + b.t.position
	bmin := b.min + b.t.position
	if a.shape == Shape.BoundingBox && b.shape == Shape.BoundingBox {
		if amax.x > bmin.x &&
			amax.y > bmin.y &&
			amax.z > bmin.z &&
			amin.x < bmax.x &&
			amin.y < bmax.y &&
			amin.z < bmax.z {
				return true
			}
	}
	return false
}

distance_sqr :: proc(a: ^Collider, b: ^Collider) -> f32 {
	d := b.t.position - a.t.position
	return d.x * d.x + d.y * d.y + d.z * d.z
}
distance :: proc(a: ^Collider, b: ^Collider) -> f32 {
	return math.sqrt(distance_sqr(a, b))
}

in_range :: proc(a: ^Collider, b: ^Collider, distance: f32) -> bool {
	return distance_sqr(a, b) <= distance * distance
}
