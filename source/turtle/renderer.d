// Manage drawing.
module turtle.renderer;

public import dplug.canvas;
public import dplug.graphics.color;
public import dplug.graphics.image;
public import colors;

interface IRenderer
{
    /// Start drawing, return a Canvas and a framebuffer.
    void beginFrame(RGBA8 clearColor, Canvas** canvas, ImageRef!RGBA* framebuffer);

    /// Mark end of drawing.
    void endFrame();

    /// Get width and height of the frame returned by the last call to `beginFrame`.
    void getFrameSize(int* width, int* height);
}