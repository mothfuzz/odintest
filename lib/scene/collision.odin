package scene
import "../collision"

//delegate to collision
spatial_hash :: proc(s: ^Scene, $T: typeid) -> ^collision.SpatialHash {
	c := (^ActorTable(T))(s.controllers[T].table)
	return &c.spatial_hash
}
neighbors :: proc(s: ^Scene, c: ^collision.Collider, $T: typeid) -> [dynamic]^collision.Collider {
	return collision.neighbors(c, spatial_hash(s, T))
}
all :: proc(s: ^Scene, $T: typeid) -> [dynamic]^collision.Collider {
	return collision.all(spatial_hash(s, T))
}
colliders :: proc(s: ^Scene, c: ^collision.Collider, $T: typeid) -> [dynamic]^collision.Collider {
	return collision.colliders(c, spatial_hash(s, T))
}
