package scene

send :: proc(s: ^Scene, id: ActorId, subject: string, body: any) {
	if id == 0 {
		return
	}
	if !(id in s.actor_types) {
		return
	}
	s.controllers[s.actor_types[id]]->send(s, id, subject, body)
}

subscribe :: proc(s: ^Scene, id: ActorId, subject: string) {
	if _, ok := s.topics[subject]; !ok {
		s.topics[subject] = make(map[ActorId]struct{})
	}
	t := &s.topics[subject]
	t[id] = {}
}
unsubscribe :: proc(s: ^Scene, id: ActorId, subject: string) {
	if _, ok := s.topics[subject]; ok {
		delete_key(&s.topics[subject], id)
	}
}
publish :: proc(s: ^Scene, subject: string, body: any) {
	if _, ok := s.topics[subject]; ok {
		for id in s.topics[subject] {
			send(s, id, subject, body)
		}
	}
}
