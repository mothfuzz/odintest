package collision

import "../transform"

Shape :: enum {
	CollisionMesh,
	BoundingSphere,
	BoundingBox,
}

Collider :: struct {
	//physics info
	t:     transform.Transform,
	shape: Shape,
	min:   [3]f32,
	max:   [3]f32,

	//location info
	parent: ^SpatialHash,
	cells: [dynamic][3]int,
}

create_bounding_box :: proc(l: ^SpatialHash, t: ^transform.Transform, w: f32, h: f32, d: f32) -> ^Collider {
	c := new(Collider)
	c^ = {t^, Shape.BoundingBox, {-w/2, -h/2, -d/2}, {w/2, h/2, d/2}, l, make([dynamic][3]int, 0)}
	return c
}

//spatial hash :3
Chunk :: struct {
	location: [3]int,
	colliders: map[^Collider]struct{},
}
SpatialHash :: distinct map[[3]int]^Chunk

@(private)
cell_size :: 32
@(private)
hash :: proc(p: [3]f32) -> [3]int {
	return {int(p.x / cell_size), int(p.y / cell_size), int(p.z / cell_size)}
}

@(private)
get_chunk :: proc(s: ^SpatialHash, cell: [3]int) -> ^Chunk {
	if c, ok := s[cell]; !ok {
		s[cell] = new(Chunk)
		s[cell].colliders = make(map[^Collider]struct{})
		s[cell].location = cell
	}
	return s[cell]
}

update :: proc(c: ^Collider, t: ^transform.Transform) {
	for cell in &c.cells {
		delete_key(&c.parent[cell].colliders, c)
	}
	clear(&c.cells)

	c.t = t^;

	//apply transform and update c.max/c.min with new extents
	//...

	//1. find all applicable cells
	cmax := hash(c.max + c.t.position)
	//cmax := hash((c.max + c.t.position) * c.t.scale)
	cmin := hash(c.min + c.t.position)
	//cmin := hash((c.min + c.t.position) * c.t.scale)
	//2. hash them cells
	for i := cmin.x; i <= cmax.x; i+=1 {
		for j := cmin.y; j <= cmax.y; j+=1 {
			for k := cmin.z; k <= cmax.z; k+=1 {
				append(&c.cells, [3]int{i, j, k})
				chunk := get_chunk(c.parent, {i, j, k})
				chunk.colliders[c] = {}
			}
		}
	}
}

destroy_collider :: proc(c: ^Collider) {
	for cell in &c.cells {
		delete_key(&c.parent[cell].colliders, c)
	}
	delete(c.cells)
	free(c)
}

create_spatial_hash :: proc() -> SpatialHash {
	return make(SpatialHash)
}
destroy_spatial_hash :: proc(l: ^SpatialHash) {
	for cell in l {
		for c in l[cell].colliders {
			delete(c.cells)
			free(c)
		}
		delete(l[cell].colliders)
		free(l[cell])
	}
	delete(l^)
}

destroy :: proc {
	destroy_collider,
	destroy_spatial_hash,
}



neighbors :: proc(c: ^Collider, s: ^SpatialHash) -> [dynamic]^Collider {
	neighbors := make([dynamic]^Collider, 0, 0, context.temp_allocator)
	for cell in c.cells {
		for k in get_chunk(s, cell).colliders {
			if k != c {
				append(&neighbors, k)
			}
		}
	}

	return neighbors
}

colliders :: proc(c: ^Collider, s: ^SpatialHash) -> [dynamic]^Collider {
	neighbors := neighbors(c, s)
	colliders := make([dynamic]^Collider, 0, 0, context.temp_allocator)
	for n in neighbors {
		if test(c, n) {
			append(&colliders, n)
		}
	}
	delete(neighbors)
	return colliders
}

all :: proc(s: ^SpatialHash) -> [dynamic]^Collider {
	colliders := make([dynamic]^Collider, 0, 0, context.temp_allocator)
	for cell in s {
		for collider in &s[cell].colliders {
			append(&colliders, collider)
		}
	}
	return colliders
}
