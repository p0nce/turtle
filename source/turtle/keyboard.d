module turtle.keyboard;

import std.string;
import bindbc.sdl;

alias KeyConstant = string;
//alias KeyScancode = SDL_Scancode;


/// Provides an interface to the user's keyboard.
/// Only a few KeyConstants are known, and the user can poll their status.
/// The other keys go through text input SDL system, so that shift + key behave correctly.
class Keyboard
{
    this()
    {
        _state[] = false;
    }

    /// Returns: true if key is pressed.
    bool isDown(KeyConstant key)
    {
        SDL_Keycode sdlk = getSDLKeycodeFromKey(key);
        SDL_Scancode sdlsc = SDL_GetScancodeFromKey(sdlk);
        return _state[ sdlsc ];
    }

package:

    static SDL_Keycode getSDLKeycodeFromKey(KeyConstant key)
    {
        foreach(ref k; allKeys)
            if (k.tcon == key)
                return k.sdlk;
        throw new Exception(format("Unknown key constant: %s", key));
    }

    static KeyConstant getKeyFromSDLKeycode(SDL_Keycode code)
    {
        foreach(ref k; allKeys)
            if (k.sdlk == code)
                return k.tcon;
        return null; // not found
    }

    // Mark key as pressed and return previous state.
    bool markKeyAsPressed(SDL_Scancode scancode)
    {
        bool oldState = _state[scancode];
        _state[scancode] = true;
        return oldState;
    }

    // Mark key as released and return previous state.
    bool markKeyAsReleased(SDL_Scancode scancode)
    {
        bool oldState = _state[scancode];
        _state[scancode] = false;
        return oldState;
    }

    bool[SDL_NUM_SCANCODES] _state;
}

private:

struct KeyData
{
    KeyConstant tcon;
    SDL_Keycode sdlk;
}

// correspondance between our KeyConstant and 
static immutable KeyData[] allKeys = 
[
    KeyData("escape", SDLK_ESCAPE),
    KeyData("return", SDLK_RETURN),
    KeyData("left", SDLK_LEFT),
    KeyData("right", SDLK_RIGHT),
    KeyData("up", SDLK_UP),
    KeyData("down", SDLK_DOWN),
    KeyData("space", SDLK_SPACE),

    KeyData("KP_0", SDLK_KP_0),
    KeyData("KP_1", SDLK_KP_1),
    KeyData("KP_2", SDLK_KP_2),
    KeyData("KP_3", SDLK_KP_3),
    KeyData("KP_4", SDLK_KP_4),
    KeyData("KP_5", SDLK_KP_5),
    KeyData("KP_6", SDLK_KP_6),
    KeyData("KP_7", SDLK_KP_7),
    KeyData("KP_8", SDLK_KP_8),
    KeyData("KP_9", SDLK_KP_9),
];
