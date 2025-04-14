# opengl
> each branch has a diff idea

## main 
* a classic rainbow opengl hello triangle program.

## triangle
* a big solid fill triangle 
  * the triangle vertex data uses (x, y) pixel coordinates instead of clip-space
  * the vertex shader converts uses a uniform with the window resolution to convert pixel-space coordinates into clip-space
  * the triangle stays centered even if the window size changes
* mouse position changes color of the triangle
  * the fragment shader sets the fill color based on a uniform
