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
    ///ditto
    alias x = positionX;

    /// Return Y position inside the window.
    float positionY()
    {
        return _y;
    }
    ///ditto
    alias y = positionY;

    /// Returns: `true` if the left button is currently pressed.
    bool left()
    {
        return isPressed(MouseButton.left);
    }

    /// Returns: `true` if the right button is currently pressed.
    bool right()
    {
        return isPressed(MouseButton.right);
    }

    /// Returns: `true` if the middle button is currently pressed.
    bool middle()
    {
        return isPressed(MouseButton.middle);
    }

    /// Returns: `true` if the given button is currently pressed.
    bool isPressed(MouseButton button)
    {
        return pressed[button];
    }

    /// Hide mouse cursor.
    void hide()
    {
        SDL_ShowCursor(SDL_DISABLE);
    }

    /// Show mouse cursor.
    void show()
    {
        SDL_ShowCursor(SDL_ENABLE);
    }

package:
    float _x, _y;

    void markAsPressed(MouseButton button)
    {
        pressed[button] = true;
    }

    void markAsReleased(MouseButton button)
    {
        pressed[button] = false;
    }

    bool[MouseButton.max + 1] pressed;
}
