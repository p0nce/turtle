module turtle.mouse;

import std.string;
import bindbc.sdl;


enum MouseButton
{
    left,
    right,
    middle,
    x1,
    x2
}


/// Provides an interface to the user's mouse.
class Mouse
{
    this()
    {
    }

    /// Return X position inside the window.
    float positionX()
    {
        return _x;
    }

    /// Return Y position inside the window.
    float positionY()
    {
        return _y;
    }

package:
    float _x, _y;
}
