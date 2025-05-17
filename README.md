<img alt="logo" src="https://raw.githubusercontent.com/p0nce/turtle/master/logo.png" width="200">

# turtle

The `turtle` package provides a friendly and software-rendered drawing solution, for simple programs and games that happen to be written on a Friday.

## Features

`turtle` basically gives you **5** ways to draw on screen and express yourselves.

- A fast but limited software rasterizer with the `canvas()` API call. _(See project: dg2d)_
- A slow but nicer software rasterizer with the `canvasity()` API call. _(See project: canvasity)_
- A text-mode console with the `console()` API call. _(See project: text-mode)_
- An immediate software-based UI with the `ui()` API call. _(See project: microui)_
- Direct pixel access with the `framebuffer()` API call.

The draw order is as follow:
- Direct pixel access, and canvases, can happen simulaneously in the `draw` override.
- Text console is above that, but also happen in the `draw` override.
- Immediate UI is on top, and happen in the `gui()` override.


## Changelog

**Version 0.1 (March 25th 2025)** Port to SDL3.

## Examples

See `examples/` directory.





## Philosophy

https://www.youtube.com/watch?v=kfVsfOSbJY0