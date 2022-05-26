package main

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:strconv"
import gl "vendor:OpenGL"
import "vendor:glfw"

import "lib/scene"
import "lib/input"
import "config"

import "scenes/stress"

test_main :: proc() {

	glfw.WindowHint(glfw.RESIZABLE, 1)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 0)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	if (glfw.Init() != 1) {
		//お の!!
		fmt.println("GLFW error")
		return
	}
	defer glfw.Terminate()
	//monitor := glfw.GetPrimaryMonitor()
	//video_mode := glfw.GetVideoMode(monitor)
	//glfw.WindowHint(glfw.RED_BITS, video_mode.red_bits)
	//glfw.WindowHint(glfw.GREEN_BITS, video_mode.green_bits)
	//glfw.WindowHint(glfw.BLUE_BITS, video_mode.blue_bits)
	//glfw.WindowHint(glfw.REFRESH_RATE, video_mode.refresh_rate)
	//window := glfw.CreateWindow(video_mode.width, video_mode.height, "UwU", monitor, nil)
	window := glfw.CreateWindow(i32(config.WINDOW_WIDTH), i32(config.WINDOW_HEIGHT), "UwU", nil, nil)
	defer glfw.DestroyWindow(window)
	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(0)
	input.focus(window)
	defer input.free()

	gl.load_up_to(4, 0, glfw.gl_set_proc_address)
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	s := stress.stress()
	defer scene.destroy(&s)

	now := glfw.GetTime()
	then := 0.0
	frames := 0
	last_second := 0.0
	accumulator := 0.0
	title_buf: [10]byte
	title_c: cstring = nil
	defer delete_cstring(title_c)

	for (!glfw.WindowShouldClose(window)) {

		now = glfw.GetTime()
		accumulator += now - then
		then = now
		frames += 1
		if now - last_second >= 1.0 {
			title := strconv.itoa(title_buf[:], frames)
			new_title_c := strings.clone_to_cstring(title)
			glfw.SetWindowTitle(window, new_title_c)
			if title_c != nil {
				delete(title_c)
			}
			title_c = new_title_c

			frames = 0
			last_second = now
		}

		for accumulator > 0.0 {

			input.update()
			scene.update(&s)

			accumulator -= 1.0 / 125.0 //125 fps physics updates regardless of framerate
		}

		gl.ClearColor(0.1, 0.2, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		scene.draw(&s)

		glfw.SwapBuffers(window)
	}

}

main :: proc() {
    tracking_allocator: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)

	test_main()

    for key, value in tracking_allocator.allocation_map {
        fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
    }

    mem.tracking_allocator_destroy(&tracking_allocator)
}
