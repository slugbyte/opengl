# opengl

tryin to learn me some opengl

## TODO
* need to add Mesh to gl\_batch
* need to remove vao from Shader
* refactor gl\_batch to use glSubBufferData
  * set a max\_vertecies to render a a time
  * pre allocate the buffer
  * on end() flush max\_vertecies until you have fully flushed everything
  l
    * use glSubBufferData to pump data into the preallocated vbo :)
* Non Batch Render FNS
* Button + Double Click
* Slider
* ColorPicker
* BRUSH
  * sample 1 texture for alpha (try and emulate air brush)
