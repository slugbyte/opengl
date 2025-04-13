#version 330 core

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D u_texture;

void main(){ 
    FragColor = texture(u_texture, vUV);
    // FragColor = vec4(1.0, 1.0, 1.0, 1.0);
}
