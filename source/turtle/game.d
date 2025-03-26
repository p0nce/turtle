module turtle.game;

import core.stdc.string: strlen;
import core.stdc.stdlib: malloc, free;
import bindbc.sdl;
import dplug.canvas;
import dplug.core.nogc;
import dplug.graphics.font;
import colors;
import textmode;
import turtle.graphics;
import turtle.renderer;
import turtle.keyboard;
import turtle.mouse;
import canvasity;
import turtle.ui.microui;


/// Main call to put in your main.d/app.d
void runGame(TurtleGame game)
{
    game.run();
    destroy(game);
}

/// Inherit from this to make a game.
class TurtleGame
{
public:
    
    /// Initialization go here. Override this function in your game.
    /// By default: do nothing.
    void load()
    {
    }

    /// Scene updates go here. Override this function in your game.
    /// By default: do nothing.
    void update(double dt)
    {
    }

    /// Drawing with a canvas goes here. Override this function in your game.
    void draw()
    {
        // by default: do nothing
    }

    /// Immediate UI system, put your UI calls here.
    void gui()
    {
        // by default: no immediate UI
    }

    /// Called whenever the window is resized. Override this function in your game.
    void resized(float width, float height)
    {
        // by default: do nothing
    }

    // TODO: merge touch and mouse events, so that touchscreen is supported by default
    // and mouse is just one-finger

    /// Callback function triggered when the mouse is moved.
    void mouseMoved(float x, float y, float dx, float dy)
    {
    }

    /// Callback function triggered when a mouse button is pressed.
    void mousePressed(float x, float y, MouseButton button, int repeat)
    {
    }

    /// Callback function triggered when a mouse button is released.
    void mouseReleased(float x, float y, MouseButton button)
    {
    }

    /// Callback function triggered when a mouse wheel is turned.
    void mouseWheel(float wheelX, float wheelY)
    {
    }

    /// Callback function triggered when a (known to Turtle) keyboard key is pressed.
    /// This can also be called by a text input event.
    void keyPressed(KeyConstant key)
    {
    }


protected:

    // <API>
    // APIs that can be used by `TurtleGame` derivatives.
    // This is loosely modelled on Love2D.

    /// Returns: A canvas
    //           This call can only be made inside a `draw` override.
    Canvas* canvas()
    {
        return _frameCanvas;
    }

    /// Returns: A better canvas, but slower for filling.
    //           This call can only be made inside a `draw` override.
    Canvasity* canvasity()
    {
        return _frameCanvasity;
    }

    /// Returns: A text-mode console.
    /// You don't need to call render, turtle will do it.
    TM_Console* console()
    {
        return &_console;
    }

    /// Returns: An ImageRef!RGBA spanning the whole screen.
    //           This call can only be made inside a `draw` override.
    ImageRef!RGBA framebuffer()
    {
        return _framebuffer;
    }

    /// Get keyboard API.
    /// Cannot be called before `load()`.
    /// Returns: The `Keyboard` object.
    Keyboard keyboard()
    {
        return _keyboard;
    }

    /// Get mouse API.
    /// Cannot be called before `load()`.
    /// Returns: The `Mouse` object.
    Mouse mouse()
    {
        return _mouse;
    }

    /// The microUI context.
    /// Use it in the `gui` callback to create your UI (always on top).
    mu_Context* ui()
    {
        return _mu_Context;
    }

    /// Width of the window. Can only be used inside a `draw` override.
    double windowWidth()
    {
        return _windowWidth;
    }

    /// Height of the window. Can only be used inside a `draw` override.
    double windowHeight()
    {
        return _windowHeight;
    }

    /// Returns: Time since beginning of `runGame()`.
    double elapsedTime()
    {
        return _elapsedTime;
    }

    /// Marks the game as finished. It will end in the next game loop iteration.
    void exitGame()
    {
        _gameShouldExit = true;
    }

    /// Changes the clear color to fill the screen with.
    void setBackgroundColor(Color col)
    {
        _backgroundColor = col.toRGBA8;
    }
    ///ditto
    void setBackgroundColor(RGBA col)
    {
        RGBA8 r8 = RGBA8(col.r, col.g, col.b, col.a);
        _backgroundColor = r8;
    }
    ///ditto
    void setBackgroundColor(const(char)[] col)
    {
        _backgroundColor = color(col).toRGBA8;
    }

    /// Changes the title of the window.
    void setTitle(const(char)[] title)
    {
        _graphics.setTitle(title);
    }

    // </API>

private:
    Canvas* _frameCanvas = null;
    Canvasity* _frameCanvasity = null;
    ImageRef!RGBA _framebuffer;
    float _windowWidth = 0.0f, 
          _windowHeight = 0.0f;

    bool _gameShouldExit = false;

    ulong _ticksSinceBeginning = 0;

    double _elapsedTime = 0, _deltaTime = 0;

    RGBA8 _backgroundColor = RGBA8(0, 0, 0, 255);

    Keyboard _keyboard;
    Mouse _mouse;    
    IGraphics _graphics;
    TM_Console _console;
    mu_Context* _mu_Context;

    // eventually those two should go into mu_Context
    Font _uiFont = null;
    float _uiFontsizePx = 16.0f;

    void run()
    {
        assert(!_gameShouldExit);

        _keyboard = new Keyboard;
        _mouse = new Mouse;

        // Default console size, you can change it in your `load()` function.
        _console.size(40, 25);

        _graphics = createGraphics();
        scope(exit) destroy(_graphics);  

        setUIFont( import("Lato-Semibold-stripped.ttf") );

        _mu_Context = cast(mu_Context*) malloc(mu_Context.sizeof);
        mu_init(_mu_Context, _uiFont);
        _mu_Context.text_width = &measureTextWidth;
        _mu_Context.text_height = &measureTextHeight;
        
        // Load override
        load();

        // TODO: sounds like bad idea to always have text input right? also coupled
        SDL_StartTextInput(cast(SDL_Window*)_graphics.getWindowObject()); 

        uint ticks = _graphics.getTicks(); 

        while(!_gameShouldExit)
        {
            // TODO: fetch events to microui

            SDL_Event event;
            while(_graphics.nextEvent(&event))
            {
                switch(event.type)
                {
                    case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
                    {
                        uint windowID = _graphics.getWindowID();
                        if (event.window.windowID != windowID)  
                            continue;

                        event.type = SDL_EVENT_QUIT;
                        SDL_PushEvent(&event);
                        break;
                    }
  
                    case SDL_EVENT_KEY_DOWN:
                    case SDL_EVENT_KEY_UP:
                        updateKeyboard(&event.key);

                        // Callback if this is a known key
                        SDL_Keycode keycode = event.key.key;
                        KeyConstant keyConstant = Keyboard.getKeyFromSDLKeycode(keycode);

                        if (keyConstant !is null) // if a known key
                        {
                            if (event.type == SDL_EVENT_KEY_DOWN)
                                keyPressed(keyConstant);
                        }
                        break;

                    case SDL_EVENT_TEXT_INPUT:
                    {
                        const(char)* ptext = event.text.text;
                        string text = ptext[0..strlen(ptext)].idup;
                        keyPressed(text);
                        break;
                    }

                    case SDL_EVENT_MOUSE_MOTION:
                    {
                        SDL_MouseMotionEvent* mevent = &event.motion;
                        _mouse._x = mevent.x;
                        _mouse._y = mevent.y;
                        mouseMoved(mevent.x, mevent.y, mevent.xrel, mevent.yrel);
                        break;
                    }

                    case SDL_EVENT_MOUSE_BUTTON_UP:
                    case SDL_EVENT_MOUSE_BUTTON_DOWN:
                    {
                        SDL_MouseButtonEvent* mevent = &event.button;
                        _mouse._x = mevent.x;
                        _mouse._y = mevent.y;
                        if (mevent.button < 0 || mevent.button > 5) 
                            goto default;
                        MouseButton button = convertSDLButtonToMouseButton(mevent.button);

                        if (event.type == SDL_EVENT_MOUSE_BUTTON_DOWN)
                        {
                            _mouse.markAsPressed(button);
                            mousePressed(mevent.x, mevent.y, button, mevent.clicks);
                        }
                        else
                        {
                            _mouse.markAsReleased(button);
                            mouseReleased(mevent.x, mevent.y, button);
                        }
                        break;
                    }

                    case SDL_EVENT_MOUSE_WHEEL:
                    {
                        SDL_MouseWheelEvent* wevent = &event.wheel;
                        mouseWheel(wevent.x, wevent.y);
                        break;
                    }

                    case SDL_EVENT_QUIT:
                        _gameShouldExit = true;
                        break;

                    default: break;
                }
            }

            uint now = _graphics.getTicks();
            uint ticksDiff = now - ticks; // TODO: this will roll over

            _ticksSinceBeginning += ticksDiff;
            ticks = now;

            // Cumulating here, so that the deltatime, when given in `update()`, doesn't drift vs this elapsedTime() if the user would sum it...
            // This is brittle, but hopefully you don't rely on _elapsedTime for anything long-term.
            _deltaTime = ticksDiff * 0.001;
            _elapsedTime += _deltaTime;

            // Update override
            update(_deltaTime);

            IRenderer renderer = _graphics.getRenderer();

            Canvas* canvas;
            Canvasity* canvasity;
            renderer.beginFrame(_backgroundColor, 
                                &canvas, 
                                &canvasity,
                                &_framebuffer);

            int width, height;
            renderer.getFrameSize(&width, &height);

            assert(canvas);
            assert(canvasity);
            _frameCanvas = canvas;
            _frameCanvasity = canvasity;

            if (_windowWidth != width || _windowHeight != height)
            {
                _windowWidth = width;
                _windowHeight = height;
                resized(_windowWidth, _windowHeight);
                _console.outbuf(_framebuffer.pixels,
                                _framebuffer.w,
                                _framebuffer.h,
                                _framebuffer.pitch);
            }

            // Draw overrides
            draw();

            // Draw console on top
            _console.render();

            // Now, render/process immediate UI
            {
                mu_begin(_mu_Context);
                gui();
                mu_end(_mu_Context);

                mu_Command *cmd = null;
                while (mu_next_command(_mu_Context, &cmd)) 
                {
                    if (cmd.type == MU_COMMAND_TEXT) 
                    {
                      /*  render_text(cmd.text.font, 
                                    cmd.text.text, 
                                    cmd.text.pos.x, 
                                    cmd.text.pos.y, 
                                    cmd.text.color); */
                    }
                    if (cmd.type == MU_COMMAND_RECT) 
                    {
                        //render_rect(cmd.rect.rect, 
                        //            cmd.rect.color);
                    }
                    if (cmd.type == MU_COMMAND_ICON) 
                    {
                        //render_icon(cmd.icon.id, cmd.icon.rect, cmd.icon.color);
                    }
                    if (cmd.type == MU_COMMAND_CLIP) 
                    {
                       // set_clip_rect(cmd.clip.rect);
                    }
                }
            }

            _frameCanvas = null;
            _framebuffer = ImageRef!RGBA.init;
            renderer.endFrame();
        } 
        
        SDL_StopTextInput(cast(SDL_Window*)_graphics.getWindowObject());
    }

    void updateKeyboard(const(SDL_KeyboardEvent*) event)
    {
        // ignore key-repeat
        if (event.repeat != 0)
            return;

        switch (event.type)
        {
            case SDL_EVENT_KEY_DOWN:
                assert(event.down == true);
                _keyboard.markKeyAsPressed(event.scancode);
                break;

            case SDL_EVENT_KEY_UP:
                assert(event.down == false);
                _keyboard.markKeyAsReleased(event.scancode);
                break;

            default:
                break;
        }
    }

    // TODO: single API point for "ui"
    // temporary
    void setUIFont(const(void)[] fontBinary)
    {
        destroyFree(_uiFont);
        _uiFont = null;
        _uiFont = mallocNew!Font(cast(ubyte[]) fontBinary);
    }

    // temporary
    void setUIFontSize(float fontSizePx)
    {
        _uiFontsizePx = fontSizePx;
    }

    ~this()
    {
        destroyFree(_uiFont);
    }

   
}

private:
nothrow @nogc:

/+
// pass this since callback doesn't have a fontSize.
struct mu_FontContext
{
    Game game;
    Font font;
}+/

int measureTextWidth(mu_Font font, const(char)*str, int len)
{
    float fontSizePx = 18.0f;
    Font dplugFont = cast(Font)font;
    assert(dplugFont);
    if (len == -1) len = cast(int) strlen(str);
    box2i b = dplugFont.measureText(str[0..len], fontSizePx, 0);
    return b.width;
}

int measureTextHeight(mu_Font font)
{
    float fontSizePx = 18.0f;
    // TODO Not sure what microUI wanted here: lineGap or size of cap?
    Font dplugFont = cast(Font)font;
    assert(dplugFont);
    box2i b = dplugFont.measureText("A", fontSizePx, 0);
    return b.height;
}

MouseButton convertSDLButtonToMouseButton(int button)
{
    switch(button)
    {
        case SDL_BUTTON_LEFT:   return MouseButton.left;
        case SDL_BUTTON_RIGHT:  return MouseButton.right;
        case SDL_BUTTON_X1:     return MouseButton.x1;
        case SDL_BUTTON_X2:     return MouseButton.x2;
        case SDL_BUTTON_MIDDLE: return MouseButton.middle;
        default:
            assert(false);
    }
}
