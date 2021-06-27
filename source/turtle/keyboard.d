module turtle.keyboard;

import std.string;
import bindbc.sdl;

alias KeyConstant = string;
//alias KeyScancode = SDL_Scancode;


/// Provides an interface to the user's keyboard.
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

    SDL_Keycode getSDLKeycodeFromKey(KeyConstant key)
    {
        foreach(ref k; allKeys)
            if (k.tcon == key)
                return k.sdlk;
        throw new Exception(format("Unknown key constant: %s", key));
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
    KeyData("left", SDLK_LEFT),
    KeyData("right", SDLK_RIGHT),
    KeyData("up", SDLK_UP),
    KeyData("down", SDLK_DOWN),
    KeyData("space", SDLK_SPACE)
];
