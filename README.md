# opengl

tryin to learn me some opengl



## TODO
* math
  * 4x4 matrix 
    * linear
    * orthographic
    * scale
    * rotate
    * skew
    * translate
* box
  * more flex
  * more responsive
  * add things based on grids?
  * add things based on %
  * debug mode (random borders, random fills)
  * alignment (top, bottom, left, right)
  * wrap?
  * style 
    * color-hot
    * color-active
    * color-disable
    * color-error
    * color-border
    * // color-a
    * // color-b
    * // color-c
    * // color-d

* fix the sketchy way slider value/handle\_position is computed
* hbox and vbox
  * .get\_cursor() ?
* render fonts
* worker thread pool for async tasks
  * file io

* Box? a nice way to render a Rect with a Theme?
  * width 
  * height
  * border
  * margin
  * pad
  * fill\_color
  * fill\_image?
* per frame arena allocator?
* more basic render fns
* Button + Double Click
* Slider
* ColorPicker
* BRUSH
  * sample 1 texture for alpha (try and emulate air brush)

## IDEA

* each gui component should have the ability to be aboslutly postioned or postioned by a
cursur?
  * or figure out how to have aboslutly postioned things use a cursur?
  * or have seperate fns `button\_absolute()` vs `button\_cursor()` or `button\_a()` or `button\_c()`
