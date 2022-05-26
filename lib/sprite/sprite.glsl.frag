#version 400

in vec2 texcoords;
out vec4 color;
uniform sampler2D tex;

void main() {
    color = texture(tex, texcoords);
}