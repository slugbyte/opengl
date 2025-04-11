#version 330 core

layout (location = 0) in vec2 aPos;
layout (location = 1) in vec3 aColor;

uniform vec2 u_window;

out vec3 vColor;
out vec2 vUV;

void main() {
    vec2 pos =(aPos / u_window * 2.0 - 1.0) * vec2(-1.0);
    vUV = pos + 0.5;
    gl_Position = vec4(pos, 0.0, 1.0);
    vColor = aColor;
}
