module turtle.game;

import bindbc.sdl;
import dplug.canvas;
import turtle.graphics;
import turtle.renderer;
import turtle.keyboard;


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

    /// Drawing goes here. Override this function in your game.
    abstract void draw();


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

    /// Get keyboard API.
    /// Cannot be called before `load()`.
    /// Returns: The `Keyboard` object.
    Keyboard keyboard()
    {
        return _keyboard;
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

    void setBackgroundColor(RGBA color)
    {
        _backgroundColor = color;
    }

    // </API>

private:
    Canvas* _frameCanvas = null;
    float _windowWidth = 0.0f, 
          _windowHeight = 0.0f;

    bool _gameShouldExit = false;

    ulong _ticksSinceBeginning = 0;

    double _elapsedTime = 0, _deltaTime = 0;

    RGBA _backgroundColor = RGBA(0, 0, 0, 255);

    Keyboard _keyboard;

    void run()
    {
        assert(!_gameShouldExit);

        _keyboard = new Keyboard;

        IGraphics graphics = createGraphics();
        scope(exit) destroy(graphics);   

        // Load override
        load();

        uint ticks = graphics.getTicks(); 

        while(!_gameShouldExit)
        {
            SDL_Event event;
            while(graphics.nextEvent(&event))
            {
                switch(event.type)
                {
                    case SDL_WINDOWEVENT:
                        {
                            uint windowID = graphics.getWindowID();
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


                    case SDL_QUIT:
                        _gameShouldExit = true;
                        break;

                    default: break;
                }
            }

            uint now = graphics.getTicks();
            uint ticksDiff = now - ticks; // TODO: this will roll over

            _ticksSinceBeginning += ticksDiff;
            ticks = now;

            // Cumulating here, so that the deltatime, when given in `update()`, doesn't drift vs this elapsedTime() if the user would sum it...
            // This is brittle, but hopefully you don't rely on _elapsedTime for anything long-term.
            _deltaTime = ticksDiff * 0.001;
            _elapsedTime += _deltaTime;            

            // Update override
            update(_deltaTime);

            IRenderer renderer = graphics.getRenderer();

            Canvas* canvas = renderer.beginFrame(_backgroundColor);

            int width, height;
            renderer.getFrameSize(&width, &height);

            _frameCanvas = canvas;
            _windowWidth = width;
            _windowHeight = height;

            // Draw override
            draw();
            _frameCanvas = null;
            renderer.endFrame();
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