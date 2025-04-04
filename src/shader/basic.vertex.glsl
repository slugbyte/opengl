#version 330 core

layout (location = 0) in vec2 aPos;
uniform vec2 u_resolution;

void main() {
    gl_Position = vec4(aPos / u_resolution, 0.0, 1.0);
}
