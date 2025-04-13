#version 330 core

layout (location = 0) in vec2 aPos;
layout (location = 1) in vec4 aColor;
layout (location = 2) in vec2 aUV;

uniform vec2 u_window;

out vec4 vColor;
out vec2 vUV;

void main() {
    vec2 pos =(aPos / u_window * 2.0 - 1.0) * vec2(1.0, -1.0);

    vUV = aUV;
    vColor = aColor;
    gl_Position = vec4(pos, 0.0, 1.0);
}
