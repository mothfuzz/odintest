package test_sprite

import "../../config"
import "../../lib/scene"
import "../../lib/collision"
import "../../lib/sprite"
import "../../lib/transform"
import "core:math/rand"

//everything and the kitchen sink in one actor

TestSprite :: struct {
	t:        transform.Transform,
	s:        ^sprite.Sprite,
	c:        ^collision.Collider,
	width, height: f32,
	velocity: [3]f32, //x, y, rotational
}

init :: proc(si: ^TestSprite, s: ^scene.Scene) {
	sprite.create_batch(s, "up.png", #load("up.png")) //compile it in with the sprite!
	si.s = sprite.create(s, "up.png")
	si.t = transform.origin()
	si.t.position.x = rand.float32_range(-config.WINDOW_WIDTH/2, config.WINDOW_WIDTH/2)
	si.t.position.y = rand.float32_range(-config.WINDOW_HEIGHT/2, config.WINDOW_HEIGHT/2)
	si.width = f32(sprite.width(si.s)) / 1.5
	si.height = f32(sprite.height(si.s)) / 1.5
	si.c = collision.create_bounding_box(scene.spatial_hash(s, TestSprite), &si.t, si.width, si.height, 1.0)
	si.t.scale = {si.width, si.height, 1.0}
	si.velocity.x = rand.float32_range(-1, 1)
	si.velocity.y = rand.float32_range(-1, 1)
	si.velocity.z = 0//rand.float32_range(0, 0.1)
	scene.subscribe(s, scene.id(s, si), "test_messages")
}

import "core:fmt"
TestMessage :: struct {
	i: i32,
}
mailbox :: proc(si: ^TestSprite, s: ^scene.Scene, subject: string, body: any) {
	if test, ok := body.(TestMessage); ok {
		fmt.println("got a testmessage:", test.i)
	} else {
		fmt.println(subject, body)
	}
}

update :: proc(si: ^TestSprite, s: ^scene.Scene) {
	transform.translate(&si.t, {si.velocity.x, si.velocity.y, 0.0})
	transform.rotatez(&si.t, si.velocity.z)
	if si.t.position.x < -config.WINDOW_WIDTH / 2 || si.t.position.x > config.WINDOW_WIDTH / 2 {
		si.velocity.x = -si.velocity.x
	}
	if si.t.position.y < -config.WINDOW_HEIGHT / 2 || si.t.position.y > config.WINDOW_HEIGHT / 2 {
		si.velocity.y = -si.velocity.y
	}
	sprite.update(si.s, &si.t)
	collision.update(si.c, &si.t)
	si.velocity.z *= 0.9
	si.t.scale.x = si.width
	si.t.scale.y = si.height
	for n in scene.colliders(s, si.c, TestSprite) {
		si.t.scale.y = -si.height
		si.velocity.z += 0.1
		si.velocity.x = -si.velocity.x
		si.velocity.y = -si.velocity.y

		scene.destroy(s, scene.id(s, si))
		scene.spawn(s, TestSprite{})
		return
	}
}

destroy :: proc(si: ^TestSprite, s: ^scene.Scene) {
	sprite.destroy(si.s)
	collision.destroy(si.c)
}

Controller :: scene.ActorFunction(TestSprite) {
	init,
	mailbox,
	update,
	destroy,
}
