package sprite

import gl "vendor:OpenGL"
import "core:os"
import "core:strings"
import "core:image"
import "core:image/png"
import "core:fmt"
import "core:math/linalg/glsl"
import "../transform"

//sort sprites into batches based on a single texture
@(private)
Batch :: struct {
	//texture data
	texture: u32,
	width, height: int,
	//instanced model data
	models: [dynamic]matrix[4, 4]f32,
	buffer: u32,
	//track live references (and keep dead ones from interfering)
	handles: [dynamic]^Sprite,
	generations: [dynamic]int,
	//link that list
	next: ^Batch,
}

//main entry point object
SpriteRenderer :: struct {
	//linked list containing all the batches
	batches: ^Batch,
	texture_map: map[string]^Batch, //used only during create, hopefully
	//render info
	vao: u32,
	positions_attrib: u32,
	texcoords_attrib: u32,
	models_attrib: u32,
	program: u32,
	tex_uniform: i32,
	view_uniform: i32,
	proj_uniform: i32,
}

Sprite :: struct {
	batch: ^Batch,
	index: int,
	//must match the batch's generation to do anything, else won't work
	generation: int,
}

//create main object
create_renderer :: proc() -> SpriteRenderer {
	s := SpriteRenderer{}

	//load shader
	vs := string(#load("sprite.glsl.vert"))
	fs := string(#load("sprite.glsl.frag"))
	if program, ok := gl.load_shaders_source(vs, fs); ok {
		s.program = program
		s.tex_uniform = gl.GetUniformLocation(s.program, "tex")
		s.view_uniform = gl.GetUniformLocation(s.program, "view")
		s.proj_uniform = gl.GetUniformLocation(s.program, "projection")
	} else {
		return {}
	}

	//set up attributes
	gl.GenVertexArrays(1, &s.vao)
	gl.BindVertexArray(s.vao)

	s.positions_attrib = 0
	s.texcoords_attrib = 1
	s.models_attrib       = 2

	positions: [4*3]f32 = {
		-0.5, -0.5, 0,
		+0.5, -0.5, 0,
		+0.5, +0.5, 0,
		-0.5, +0.5, 0,
	};
	gl.EnableVertexAttribArray(s.positions_attrib)
	pos_buf: u32
	gl.GenBuffers(1, &pos_buf)
	gl.BindBuffer(gl.ARRAY_BUFFER, pos_buf)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(f32)*4*3, &positions[0], gl.STATIC_DRAW)
	gl.VertexAttribPointer(s.positions_attrib, 3, gl.FLOAT, false, 0, 0)

	texcoords: [4*2]f32 = {
		0, 1,
		1, 1,
		1, 0,
		0, 0,
	}
	gl.EnableVertexAttribArray(s.texcoords_attrib)
	tex_buf: u32
	gl.GenBuffers(1, &tex_buf)
	gl.BindBuffer(gl.ARRAY_BUFFER, tex_buf)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(f32)*4*2, &texcoords[0], gl.STATIC_DRAW)
	gl.VertexAttribPointer(s.texcoords_attrib, 2, gl.FLOAT, false, 0, 0)

	indices: [6]u32 = {
		0, 1, 2, 0, 2, 3,
	}
	ind_buf: u32
	gl.GenBuffers(1, &ind_buf)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ind_buf)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(u32)*6, &indices[0], gl.STATIC_DRAW)

	for i in 0..<4 {
		gl.EnableVertexAttribArray(s.models_attrib+u32(i))
		gl.VertexAttribDivisor(s.models_attrib+u32(i), 1)
	}

	gl.BindVertexArray(0)

	return s
}

destroy_renderer :: proc(sr: ^SpriteRenderer) {
	batch := sr.batches
	for batch != nil {
		next := batch.next
		destroy_batch(batch)
		batch = next
	}
	delete(sr.texture_map)
	gl.DeleteProgram(sr.program)
	gl.DeleteVertexArrays(1, &sr.vao)
}

create_batch :: proc(sr: ^SpriteRenderer, texture: string, texture_png: []u8 = nil) {
	if texture in sr.texture_map {
		return
	}

	s: ^Batch = new(Batch)
	//load texture
	format := gl.RGB
	img: ^image.Image
	err: image.Error
	if texture_png == nil {
		img, err = png.load(texture)
	} else {
		img, err = png.load(texture_png)
	}
	if(err != nil) {
		fmt.eprintln(texture, err)
		return
	}
	gl.GenTextures(1, &s.texture)
	s.width = img.width
	s.height = img.height
	if img.channels == 4 {
		format = gl.RGBA
	}
	gl.BindTexture(gl.TEXTURE_2D, s.texture)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, i32(s.width), i32(s.height), 0, u32(format), gl.UNSIGNED_BYTE, &img.pixels.buf[0])
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST_MIPMAP_NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	gl.GenerateMipmap(gl.TEXTURE_2D)
	png.destroy(img)
	//create buffers
	s.models = make([dynamic]matrix[4, 4]f32, 0)
	s.handles = make([dynamic]^Sprite, 0)
	s.generations = make([dynamic]int, 0)
	gl.GenBuffers(1, &s.buffer)
	//attach
	s.next = sr.batches
	sr.texture_map[texture] = s
	sr.batches = s
}
destroy_batch :: proc(batch: ^Batch) {
	gl.DeleteTextures(1, &batch.texture)
	gl.DeleteBuffers(1, &batch.buffer)
	for s in batch.handles {
		free(s)
	}
	delete(batch.models)
	delete(batch.handles)
	delete(batch.generations)
	free(batch)
}

//metadata
width :: proc(sprite: ^Sprite) -> int {
	return sprite.batch.width
}
height :: proc(sprite: ^Sprite) -> int {
	return sprite.batch.height
}


//create, update, delete individual sprites
create :: proc(sr: ^SpriteRenderer, texture: string) -> ^Sprite {
	if _, ok := sr.texture_map[texture]; !ok {
		create_batch(sr, texture)
	}
	s: ^Batch = sr.texture_map[texture]
	origin := (matrix[4, 4]f32)(glsl.identity(glsl.mat4))
	append(&s.models, origin)
	handle := new(Sprite)
	handle.batch = s
	handle.index = len(s.handles)
	handle.generation = 0
	append(&s.handles, handle)
	append(&s.generations, 0)
	return handle
}

update :: proc(s: ^Sprite, t: ^transform.Transform) {
	batch := s.batch
	if s.index >= len(batch.handles) || batch.generations[s.index] != s.generation {
		return
	}
	s.batch.models[s.index] = transform.mat4(t)
}

destroy_sprite :: proc(s: ^Sprite) {
	batch := s.batch
	if s.index >= len(batch.handles) || batch.generations[s.index] != s.generation {
		return
	}
	replacement := len(batch.handles) - 1
	batch.handles[replacement].index = s.index
	batch.handles[replacement].generation = s.generation + 1
	batch.generations[replacement] = s.generation + 1
	unordered_remove(&batch.models, s.index)
	unordered_remove(&batch.handles, s.index)
	unordered_remove(&batch.generations, s.index)
	free(s)
}

destroy :: proc {
	destroy_sprite,
	destroy_batch,
	destroy_renderer,
}

//render each batch, sorting by texture
render :: proc(sr: ^SpriteRenderer, view: ^matrix[4, 4]f32 = nil, projection: ^matrix[4, 4]f32 = nil) {
	gl.BindVertexArray(sr.vao)
	gl.UseProgram(sr.program)
	for batch := sr.batches; batch != nil; batch = batch.next {
		if len(batch.models) == 0 {
			continue
		}
		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, batch.texture)
		gl.Uniform1i(sr.tex_uniform, 0)
		if(view != nil && projection != nil) {
			gl.UniformMatrix4fv(sr.view_uniform, 1, false, &view[0, 0])
			gl.UniformMatrix4fv(sr.proj_uniform, 1, false, &projection[0, 0])
		} else {
			ident: matrix[4, 4]f32 = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
			gl.UniformMatrix4fv(sr.view_uniform, 1, false, &ident[0, 0])
			gl.UniformMatrix4fv(sr.proj_uniform, 1, false, &ident[0, 0])
		}
		gl.BindBuffer(gl.ARRAY_BUFFER, batch.buffer)
			gl.BufferData(gl.ARRAY_BUFFER, size_of(matrix[4, 4]f32)*len(batch.models), &batch.models[0], gl.DYNAMIC_DRAW)
		for i in 0..<4 {
			gl.VertexAttribPointer(sr.models_attrib+u32(i), 4, gl.FLOAT, false, size_of(matrix[4, 4]f32), uintptr(i*size_of([4]f32)))
		}
		gl.DrawElementsInstanced(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil, i32(len(batch.models)))
	}
}
