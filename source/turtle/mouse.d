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

    /// Returns: `true` if the button is currently pressed.
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
