package input

import "vendor:glfw"

@(private)
window_handle: glfw.WindowHandle
@(private)
buttons_now : map[string]bool
@(private)
buttons_then : map[string]bool

focus :: proc(window: glfw.WindowHandle) {
	glfw.SetKeyCallback(window, key_callback)
	glfw.SetMouseButtonCallback(window, mouse_button_callback)
	window_handle = window
}

free :: proc() {
	delete(buttons_now)
	delete(buttons_then)
}

button_down :: proc(btn: string) -> bool {
	return buttons_now[btn] || buttons_then[btn]
}

button_pressed :: proc(btn: string) -> bool {
	return buttons_now[btn] && !buttons_then[btn]
}

button_released :: proc(btn: string) -> bool {
	return buttons_then[btn] && !buttons_now[btn]
}

@(private)
key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	switch key {
	case glfw.KEY_A:
		buttons_now["a"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_B:
		buttons_now["b"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_C:
		buttons_now["c"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_D:
		buttons_now["d"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_E:
		buttons_now["e"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_F:
		buttons_now["f"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_G:
		buttons_now["g"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_H:
		buttons_now["h"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_I:
		buttons_now["i"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_J:
		buttons_now["j"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_K:
		buttons_now["k"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_L:
		buttons_now["l"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_M:
		buttons_now["m"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_N:
		buttons_now["n"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_O:
		buttons_now["o"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_P:
		buttons_now["p"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_Q:
		buttons_now["q"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_R:
		buttons_now["r"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_S:
		buttons_now["s"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_T:
		buttons_now["t"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_U:
		buttons_now["u"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_V:
		buttons_now["v"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_W:
		buttons_now["w"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_X:
		buttons_now["x"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_Y:
		buttons_now["y"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_Z:
		buttons_now["z"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_0:
		buttons_now["0"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_1:
		buttons_now["1"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_2:
		buttons_now["2"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_3:
		buttons_now["3"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_4:
		buttons_now["4"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_5:
		buttons_now["5"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_6:
		buttons_now["6"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_7:
		buttons_now["7"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_8:
		buttons_now["8"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_9:
		buttons_now["9"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_LEFT:
		buttons_now["left"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_RIGHT:
		buttons_now["right"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_UP:
		buttons_now["up"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_DOWN:
		buttons_now["down"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_SPACE:
		buttons_now["space"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_ENTER:
		buttons_now["return"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_LEFT_SHIFT:
		buttons_now["shift"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_LEFT_CONTROL:
		buttons_now["ctrl"] = (action == glfw.PRESS || action == glfw.REPEAT)
	case glfw.KEY_LEFT_ALT:
		buttons_now["alt"] = (action == glfw.PRESS || action == glfw.REPEAT)
	}
}

@(private)
mouse_button_callback :: proc "c" (window: glfw.WindowHandle, key, action, mods: i32) {
	switch key {
	case glfw.MOUSE_BUTTON_LEFT:
		buttons_now["mouse_left"] = (action == glfw.PRESS)
	case glfw.MOUSE_BUTTON_MIDDLE:
		buttons_now["mouse_middle"] = (action == glfw.PRESS)
	case glfw.MOUSE_BUTTON_RIGHT:
		buttons_now["mouse_right"] = (action == glfw.PRESS)
	}
}

cursor :: proc() -> [2]int {
	x, y := glfw.GetCursorPos(window_handle)
	return {int(x), int(y)}
}

update :: proc() {
	glfw.PollEvents()
	if glfw.GetKey(window_handle, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window_handle, true)
	}
	for k, v in &buttons_now {
		buttons_then[k] = v
	}
}
