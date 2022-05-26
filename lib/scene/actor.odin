package scene

import "../collision"

ActorId :: distinct u64

ActorFunction :: struct(T: typeid) {
	init: proc(^T, ^Scene),
	mailbox: proc(^T, ^Scene, string, any),
	update: proc(^T, ^Scene),
	destroy: proc(^T, ^Scene),
}

@(private)
Instance :: struct(T: typeid) {
	id: ActorId,
	data: T,
}

@(private)
ActorTable :: struct(T: typeid) {
	functions: ActorFunction(T),
	spawns: [dynamic]Instance(T), //spawn/init
	kills: [dynamic]Instance(T), //destroy
	instances: [dynamic]Instance(T), //update
	ids: map[ActorId]int,
	spatial_hash: collision.SpatialHash,
}

@(private)
ActorController :: struct {
	//type-specific info
	table: rawptr,
	//keep around some procs so that ActorControllers know how to manage themselves
	deregister: proc(ActorController, ^Scene),
	update: proc(ActorController, ^Scene),
	destroy: proc(ActorController, ^Scene, ActorId),
	send: proc(ActorController, ^Scene, ActorId, string, any),
}

id :: proc(s: ^Scene, p: ^$T) -> ActorId {
	if c, ok := s.controllers[T]; !ok {
		return 0
	}

	c := (^ActorTable(T))(s.controllers[T].table)

	for i in &c.instances {
		if &i.data == p {
			return i.id
		}
	}

	return 0
}

register :: proc(s: ^Scene, functions: ActorFunction($T)) {
	table := new(ActorTable(T))
	table.functions = functions
	table.instances = make([dynamic]Instance(T), 0)
	table.spawns = make([dynamic]Instance(T), 0)
	table.kills = make([dynamic]Instance(T), 0)
	table.ids = make(map[ActorId]int)
	table.spatial_hash = collision.create_spatial_hash()
	s.controllers[T] = {
		table,
		//deregister
		proc(c: ActorController, s: ^Scene) {
			t := (^ActorTable(T))(c.table)
			if t.functions.destroy != nil {
				for i in &t.instances {
					t.functions.destroy(&i.data, s)
				}
				for i in &t.kills {
					t.functions.destroy(&i.data, s)
				}
			}
			collision.destroy_spatial_hash(&t.spatial_hash)
			delete(t.instances)
			delete(t.spawns)
			delete(t.kills)
			delete(t.ids)
			free(t)
		},
		//update
		proc(c: ActorController, s: ^Scene) {
			t := (^ActorTable(T))(c.table)
			//spawn new actors
			for i in &t.spawns {
				t.ids[i.id] = len(t.instances)
				append(&t.instances, i)

				if t.functions.init != nil {
					t.functions.init(&t.instances[t.ids[i.id]].data, s)
				}
			}
			clear(&t.spawns)
			//update existing actors
			for i in &t.instances {
				if t.functions.update != nil {
					t.functions.update(&i.data, s)
				}
			}
			//delete killed actors
			for i in &t.kills {
				if t.functions.destroy != nil {
					t.functions.destroy(&t.instances[t.ids[i.id]].data, s)
				}

				replaced := t.instances[len(t.instances) - 1].id
				t.ids[replaced] = t.ids[i.id]
				unordered_remove(&t.instances, t.ids[i.id])
				delete_key(&t.ids, i.id)
			}
			clear(&t.kills)
		},
		//destroy
		proc(c: ActorController, s: ^Scene, id: ActorId) {
			t := (^ActorTable(T))(c.table)
			if index, ok := t.ids[id]; ok {
				append(&t.kills, t.instances[index])
			}
		},
		//send
		proc(c: ActorController, s: ^Scene, id: ActorId, subject: string, body: any) {
			t := (^ActorTable(T))(c.table)
			if t.functions.mailbox != nil {
				t.functions.mailbox(&t.instances[t.ids[id]].data, s, subject, body)
			}
		},
	}
}
