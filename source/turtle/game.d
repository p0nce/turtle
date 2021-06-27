module turtle.game;

import bindbc.sdl;
import dplug.canvas;
import turtle.graphics;
import turtle.renderer;
import turtle.keyboard;
import turtle.mouse;
import turtle.node2d;
import dchip.cpSpace;
import dchip.cpSpaceStep;

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
    void setBackgroundColor(RGBA color)
    {
        _backgroundColor = color;
    }

    /// Changes the title of the window.
    void setTitle(const(char)[] title)
    {
        _graphics.setTitle(title);
    }

    /// Root of the scene.
    Node root()
    {
        return _root;
    }

    // </API>

private:
    Canvas* _frameCanvas = null;
    ImageRef!RGBA _framebuffer;
    float _windowWidth = 0.0f, 
          _windowHeight = 0.0f;

    bool _gameShouldExit = false;

    ulong _ticksSinceBeginning = 0;

    double _elapsedTime = 0, _deltaTime = 0;

    RGBA _backgroundColor = RGBA(0, 0, 0, 255);

    Keyboard _keyboard;
    Mouse _mouse;

    Node _root; // root of the scene

    cpSpace* _space;

    double _physicsAccum = 0.0;

    IGraphics _graphics;

    void run()
    {
        assert(!_gameShouldExit);

        _keyboard = new Keyboard;
        _mouse = new Mouse;
        _root = new Node;

        _space = cpSpaceNew();

        _graphics = createGraphics();
        scope(exit) destroy(_graphics);   

        // Load override
        load();

        uint ticks = _graphics.getTicks(); 

        while(!_gameShouldExit)
        {
            SDL_Event event;
            while(_graphics.nextEvent(&event))
            {
                switch(event.type)
                {
                    case SDL_WINDOWEVENT:
                        {
                            uint windowID = _graphics.getWindowID();
                            if (event.window.windowID != windowID)  
                                continue;

                            switch (event.window.event)
                            {
                                case SDL_WINDOWEVENT_CLOSE:
                                    event.type = SDL_QUIT;
                                    SDL_PushEvent(&event);
                                    break;
                                default:
                                    break;
                            }
                            break;
                        }

                    case SDL_KEYDOWN:
                    case SDL_KEYUP:
                        updateKeyboard(&event.key);
                        break;

                    case SDL_MOUSEMOTION:
                    {
                        SDL_MouseMotionEvent* mevent = &event.motion;
                        _mouse._x = mevent.x;
                        _mouse._y = mevent.y;
                        mouseMoved(mevent.x, mevent.y, mevent.xrel, mevent.yrel);
                        break;
                    }

                    case SDL_MOUSEBUTTONUP:
                    case SDL_MOUSEBUTTONDOWN:
                    {
                        SDL_MouseButtonEvent* mevent = &event.button;
                        _mouse._x = mevent.x;
                        _mouse._y = mevent.y;
                        if (mevent.button < 0 || mevent.button > 5) 
                            goto default;
                        MouseButton button = convertSDLButtonToMouseButton(mevent.button);

                        if (event.type == SDL_MOUSEBUTTONDOWN)
                        {
                            mousePressed(mevent.x, mevent.y, button, mevent.clicks);
                        }
                        else
                            mouseReleased(mevent.x, mevent.y, button);
                        break;
                    }

                    case SDL_MOUSEWHEEL:
                    {
                        SDL_MouseWheelEvent* wevent = &event.wheel;
                        mouseWheel(wevent.x, wevent.y);
                        break;
                    }

                    case SDL_QUIT:
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
            updatePhysics(_deltaTime);
            update(_deltaTime);
            root.doUpdate(_deltaTime);

            IRenderer renderer = _graphics.getRenderer();

            Canvas* canvas;
            renderer.beginFrame(_backgroundColor, &canvas, &_framebuffer);

            int width, height;
            renderer.getFrameSize(&width, &height);

            _frameCanvas = canvas;

            if (_windowWidth != width || _windowHeight != height)
            {
                _windowWidth = width;
                _windowHeight = height;
                resized(_windowWidth, _windowHeight);
            }

            // Draw overrides
            draw();
            _frameCanvas = null;
            _framebuffer = ImageRef!RGBA.init;
            renderer.endFrame();
        } 

        cpSpaceFree(_space);
    }

    void updatePhysics(double dt)
    {
        enum PHYSICS_DT = 0.010f;
        _physicsAccum += dt;
        while( _physicsAccum > PHYSICS_DT )
        {
            cpSpaceStep(_space, PHYSICS_DT);
            _physicsAccum -= PHYSICS_DT;
        }

    }

    void updateKeyboard(const(SDL_KeyboardEvent*) event)
    {
        // ignore key-repeat
        if (event.repeat != 0)
            return;

        switch (event.type)
        {
            case SDL_KEYDOWN:
                assert(event.state == SDL_PRESSED);
                _keyboard.markKeyAsPressed(event.keysym.scancode);
                break;

            case SDL_KEYUP:
                assert(event.state == SDL_RELEASED);
                _keyboard.markKeyAsReleased(event.keysym.scancode);
                break;

            default:
                break;
        }
    }
}


void runGame(TurtleGame game)
{
    game.run();
    destroy(game);
}


MouseButton convertSDLButtonToMouseButton(int button)
{
    switch(button)
    {
        case SDL_BUTTON_LEFT: return MouseButton.left;
        case SDL_BUTTON_RIGHT: return MouseButton.right;
        case SDL_BUTTON_X1: return MouseButton.x1;
        case SDL_BUTTON_X2: return MouseButton.x2;
        case SDL_BUTTON_MIDDLE: return MouseButton.middle;
        default:
            assert(false);
    }
}
