// Manage drawing.
module turtle.renderer;

public import dplug.canvas;
public import dplug.graphics.color;

interface IRenderer
{
	/// Start drawing, return a Canvas.
    Canvas* beginFrame(RGBA clearColor);

    /// Mark end of drawing.
    void endFrame();

    /// Get width and height of the frame returned by the last call to `beginFrame`.
    void getFrameSize(int* width, int* height);
}