module turtle.game;

import core.stdc.string: strlen;
import core.stdc.stdlib: malloc, free;
import bindbc.sdl;
import dplug.canvas;
import dplug.core.nogc;
import dplug.graphics.font;
import dplug.graphics.image;
import dplug.graphics.draw;
import colors;
import textmode;
import turtle.graphics;
import turtle.renderer;
import turtle.keyboard;
import turtle.mouse;
import canvasity;
import turtle.ui;


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
    MicroUI ui()
    {
        return _mui;
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
    MicroUI _mui;

    void run()
    {
        assert(!_gameShouldExit);

        _keyboard = new Keyboard;
        _mouse = new Mouse;

        // Default console size, you can change it in your `load()` function.
        _console.size(40, 25);

        _graphics = createGraphics();
        scope(exit) destroy(_graphics);  

        
        _mui = mallocNew!MicroUI();
        _mui.setFont( import("Lato-Semibold-stripped.ttf") );
       
        
        // Load override
        load();

        // TODO: sounds like bad idea to always have text input right? also coupled
        SDL_StartTextInput(cast(SDL_Window*)_graphics.getWindowObject()); 

        uint ticks = _graphics.getTicks(); 

        while(!_gameShouldExit)
        {
            // TODO: fetch events to microui

            //void mu_input_keydown(mu_Context *ctx, int key)
            //void mu_input_keyup(mu_Context *ctx, int key)
            //void mu_input_text(mu_Context *ctx, const(char)*text) 

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
                        _mui.input_mousemove(cast(int)mevent.x, cast(int)mevent.y);
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

                        // microui

                        int ui_button = -1;
                        switch (mevent.button)
                        {
                            case SDL_BUTTON_LEFT: ui_button = MicroUI.MU_MOUSE_LEFT; break;
                            case SDL_BUTTON_RIGHT: ui_button = MicroUI.MU_MOUSE_RIGHT; break;
                            case SDL_BUTTON_MIDDLE: ui_button = MicroUI.MU_MOUSE_MIDDLE; break;
                            default: break;
                        }

                        if (ui_button != -1)
                        {
                            if (event.type == SDL_EVENT_MOUSE_BUTTON_DOWN)
                                _mui.input_mousedown(cast(int)mevent.x, cast(int)mevent.y, ui_button);
                            else
                                _mui.input_mouseup(cast(int)mevent.x, cast(int)mevent.y, ui_button);                            
                        }
                        break;
                    }

                    case SDL_EVENT_MOUSE_WHEEL:
                    {
                        SDL_MouseWheelEvent* wevent = &event.wheel;
                        mouseWheel(wevent.x, wevent.y);
                        _mui.input_scroll(cast(int)wevent.x, cast(int)wevent.y);
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
            // TODO: move this in wrapper UI object
            {
                _mui.begin();
                gui();
                _mui.end();

                _mui.renderOnFramebuf(_framebuffer);
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
