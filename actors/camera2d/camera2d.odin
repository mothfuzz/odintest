package camera2d

import "../../lib/scene"
import "../../lib/input"
import "../../lib/transform"
import "core:math/linalg/glsl"

Camera2D :: struct {}

update :: proc(self: ^Camera2D, scene: ^scene.Scene) {
	if input.button_down("left") {
		transform.translate(&scene.camera, {-1, 0, 0})
	}
	if input.button_down("right") {
		transform.translate(&scene.camera, {+1, 0, 0})
	}
	if input.button_down("up") {
		transform.rotatex(&scene.camera, glsl.radians(f32(+1.0)))
	}
	if input.button_down("down") {
		transform.rotatex(&scene.camera, glsl.radians(f32(-1.0)))
	}
}

Controller :: scene.ActorFunction(Camera2D) {
	nil,
	nil,
	update,
	nil,
}
