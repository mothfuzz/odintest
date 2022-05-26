package stress

import "../../lib/scene"

import "../../actors/test_sprite"
import "../../actors/camera2d"

import "vendor:glfw"

stress :: proc() -> scene.Scene {
	s := scene.create()

	//register
	scene.register(&s, test_sprite.Controller)
	scene.register(&s, camera2d.Controller)

	//spawn
	scene.spawn(&s, camera2d.Camera2D{})
	for i in 0 ..< 1000 {
		scene.spawn(&s, test_sprite.TestSprite{})
	}
	scene.update(&s)

	return s
}
