#version 330 core

in vec2 vUV;
in vec3 vColor;
out vec4 FragColor;

void main(){ 
    // vec2 centered = vUV * 2.0 - 1.0;
    // if (length(centered) > 1.0) {
    //     discard;
    // }

    FragColor = vec4(vColor, 1.0);
    // FragColor = vec4(1.0, 1.0, 1.0, 1.0);
}
