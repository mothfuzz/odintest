package scene

import "../collision"
import "../sprite"
import "../camera"

import "../../config"

Scene :: struct {
	baseid: ActorId,
	controllers: map[typeid]ActorController,
	actor_types: map[ActorId]typeid,
	topics: map[string]map[ActorId]struct{},
	using sprite_renderer: sprite.SpriteRenderer,
	camera: camera.Camera,
}

create :: proc() -> Scene {
	return Scene{0,
				 make(map[typeid]ActorController),
				 make(map[ActorId]typeid),
				 make(map[string]map[ActorId]struct{}),
				 sprite.create_renderer(),
				 camera.init(config.WINDOW_WIDTH, config.WINDOW_HEIGHT),
				}
}

spawn :: proc(s: ^Scene, instance: $T) -> ActorId {
	if _, ok := s.controllers[T]; !ok {
		return 0
	}
	s.baseid+=1
	s.actor_types[s.baseid] = T
	t := (^ActorTable(T))(s.controllers[T].table)
	append(&t.spawns, Instance(T){s.baseid, instance})
	return s.baseid
}

destroy_instance :: proc(s: ^Scene, id: ActorId) {
	if id == 0 {
		return
	}
	s.controllers[s.actor_types[id]]->destroy(s, id)
	delete_key(&s.actor_types, id)
}

update :: proc(s: ^Scene) {
	for t in s.controllers {
		s.controllers[t]->update(s)
	}
}
draw :: proc(s: ^Scene) {
	camera.orient(&s.camera, s.camera.position, s.camera.rotation)
	sprite.render(s, camera.viewproj(&s.camera))
}

destroy_scene :: proc(s: ^Scene) {
	for t in s.controllers {
		s.controllers[t]->deregister(s)
	}
	delete(s.controllers)
	delete(s.actor_types)
	for t in s.topics {
		delete(s.topics[t])
	}
	delete(s.topics)
	sprite.destroy_renderer(s)
}

destroy :: proc {
	destroy_instance,
	destroy_scene,
}
