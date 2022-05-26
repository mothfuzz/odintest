package camera

import "core:math/linalg/glsl"
import "core:math"
import "../transform"

Camera :: struct {
	using t: transform.Transform,
	view: matrix[4, 4]f32,
	projection: matrix[4, 4]f32,
}

init :: proc(width: f32, height: f32) -> Camera {
	c := Camera{}

	z_2d := math.sqrt(math.pow(height, 2) - math.pow(height/2.0, 2))
	c.position = {0, 0, z_2d}
	c.rotation = quaternion(1, 0, 0, 0)
	c.scale = {width, height, z_2d} //keep track of the z_2d

	//c.projection = (matrix[4, 4]f32)(glsl.mat4Ortho3d(-width/2, width/2, -height/2, height/2, 0.1, 1000.0))
	c.projection = (matrix[4, 4]f32)(glsl.mat4Perspective(glsl.radians(f32(60.0)), width / height, 0.1, 1000.0))
	c.view = (matrix[4, 4]f32)(glsl.mat4LookAt({0, 0, z_2d}, {0, 0, 0}, {0, 1, 0}))

	return c
}

update :: proc(c: ^Camera, t: ^transform.Transform) {
	c.position = t.position
	c.rotation = t.rotation
}

orient :: proc(c: ^Camera, position: [3]f32, orientation: quaternion128) {
	c.position = position
	c.rotation = orientation

	//assume forward vector is {0, 0, 1} thus,
	//orientation * {0, 0, 1}
	//aka orientation->mat3 * {0, 0, 1} = {mat[0, 2], mat[1, 2], mat[2, 2]}
	forward: [3]f32 = {0, 0, 1}
	forward = {
		2 * c.rotation.x * c.rotation.z + 2 * c.rotation.y * c.rotation.w,
		2 * c.rotation.y * c.rotation.z - 2 * c.rotation.x * c.rotation.w,
		1 - 2 * c.rotation.x * c.rotation.x - 2 * c.rotation.y * c.rotation.y,
	}
	c.view = (matrix[4, 4]f32)(glsl.mat4LookAt(glsl.vec3(c.position), glsl.vec3(c.position - forward), {0, 1, 0}))
}

width :: proc(c: ^Camera) -> f32 {
	return c.scale[0]
}
height :: proc(c: ^Camera) -> f32 {
	return c.scale[1]
}
z2d :: proc(c: ^Camera) -> f32 {
	return c.scale[2]
}

//convenience functions if you don't wanna call camera.orient right before viewproj
translate :: proc(c: ^Camera, v: [3]f32) {
	transform.translate(c, v)
	orient(c, c.position, c.rotation)
}

rotatex :: proc(c: ^Camera, angle: f32) {
	transform.rotatex(c, angle)
	orient(c, c.position, c.rotation)
}
rotatey :: proc(c: ^Camera, angle: f32) {
	transform.rotatey(c, angle)
	orient(c, c.position, c.rotation)
}
rotatez :: proc(c: ^Camera, angle: f32) {
	transform.rotatez(c, angle)
	orient(c, c.position, c.rotation)
}

viewproj :: proc(c: ^Camera) -> (^matrix[4, 4]f32, ^matrix[4,4]f32) {
	return &c.view, &c.projection
}
