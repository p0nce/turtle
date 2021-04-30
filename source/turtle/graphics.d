// Manage interface with OS.
module turtle.graphics;

import core.stdc.string;
version(Windows)
{
    import core.sys.windows.windef;
    import core.sys.windows.winuser;
    import core.sys.windows.winbase;
}

import std.string;

enum EMULATE_SDL = false;
static if (EMULATE_SDL)
    import dsdl;
else
    import bindbc.sdl;

import turtle.renderer;
import dplug.graphics.image;
import dplug.graphics.color;
import dplug.graphics.drawex;

IGraphics createGraphics()
{
    return new Graphics();
}

interface IGraphics
{
    /// Get the next event.
    bool nextEvent(SDL_Event* event);

    /// Mark beginning of frame.
    IRenderer getRenderer();

    int getTicks();

    uint getWindowID();

    void setTitle(string title);
}

enum RENDERER = true;


class Graphics : IGraphics, IRenderer
{
    this()
    {
        bool enableHIDPI = true;

        if (enableHIDPI)
            makeProcessDPIAware();
        loadSDLLibrary();       

        if (enableHIDPI)
        {
            SDL_SetHint("SDL_HINT_RENDER_SCALE_QUALITY", "0");
            SDL_SetHint("SDL_HINT_VIDEO_HIGHDPI_ENABLED", "1");
        }
        SDL_WindowFlags flags = SDL_WINDOW_SHOWN
                              | SDL_WINDOW_RESIZABLE
                              | SDL_WINDOW_MOUSE_FOCUS
                              //| SDL_WINDOW_FULLSCREEN_DESKTOP
                              | SDL_WINDOW_INPUT_FOCUS;

        if (enableHIDPI)
            flags |= SDL_WINDOW_ALLOW_HIGHDPI;

        _window = SDL_CreateWindow("v2d", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480, flags);

        if (RENDERER)
        {
            enum SDL_RENDERER_ACCELERATED = 0x00000002;
            enum SDL_RENDERER_PRESENTVSYNC = 0x00000004;
            _renderer = SDL_CreateRenderer(_window, -1, SDL_RendererFlags.SDL_RENDERER_ACCELERATED 
                                                      | SDL_RendererFlags.SDL_RENDERER_PRESENTVSYNC);
        }

        _buffer = new OwnedImage!RGBA;
    }

    ~this()
    {
        // close SDL
        if (RENDERER)
        {
            SDL_DestroyTexture(_texture);
            SDL_DestroyRenderer(_renderer);
        }
        SDL_DestroyWindow(_window);


        version(Windows)
        {
            if (user32_module_ != null) 
            {
                FreeLibrary(user32_module_);
                user32_module_ = null;
            }
        }
    }

    // IGraphics

    override void setTitle(string title)
    {
        SDL_SetWindowTitle(_window, toStringz(title));
    }

    override bool nextEvent(SDL_Event* event)
    {
        bool result = SDL_PollEvent(event) != 0;

        if (result)
        {
            // intercept relevant events
            switch(event.type)
            {
                case SDL_KEYDOWN:
                {
                    auto key = event.key.keysym;
                    if (key.sym == SDLK_RETURN && ((key.mod & KMOD_ALT) != 0))
                        toggleFullscreen();
                    else if (key.sym == SDLK_F11)
                        toggleFullscreen();
                    break;
                }

                case SDL_WINDOWEVENT:
                {
                    uint windowID = getWindowID();
                    if (event.window.windowID != windowID)  
                        break;
                    switch (event.window.event)
                    {
                        case SDL_WINDOWEVENT_SIZE_CHANGED:
                        
                            int width = event.window.data1;
                            int height = event.window.data2;

                            if (RENDERER)
                            {
                                SDL_Rect r;
                                r.x = 0;
                                r.y = 0;
                                r.w = width;
                                r.h = height;
                                SDL_RenderSetViewport(_renderer, &r);
                            }
                            break;
                        
                        default:
                            break;
                    }
                    break;
                }
                default: break;
            }
        }
        return result;
    }

    override IRenderer getRenderer()
    {
        return this;
    }

    override int getTicks()
    {
        return cast(int) SDL_GetTicks();
    }

    override uint getWindowID()
    {
        return SDL_GetWindowID(_window);
    }

    // IRenderer

    /// Start drawing, return a Canvas initialized to the drawing area.
    override void beginFrame(RGBA clearColor, Canvas** canvas, ImageRef!RGBA* framebuffer)
    {
 
        // Get size of window.
        int w, h;
        SDL_GetRendererOutputSize(_renderer, &w, &h);

        if ((_lastKnownWidth != w) || (_lastKnownHeight != h))
        {
            _lastKnownWidth = w;
            _lastKnownHeight = h;

            int border = 0;
            int rowAlignment = 1;
            int xMultiplicity = 1;
            int trailingSamples = 3; // for dplug:canvas
            _buffer.size(w, h, border, rowAlignment, xMultiplicity, trailingSamples);

            fillWithClearColor(clearColor);

            _texture = SDL_CreateTexture(_renderer, SDL_PIXELFORMAT_RGBA32, SDL_TEXTUREACCESS_STREAMING, w, h);

        }

        if (clearColor.a == 255)
        {
            fillWithClearColor(clearColor);
        }
        else
        {
            // blend color with previous to make a cheap motion blur
            for (int y = 0; y < _lastKnownHeight; ++y)
            {
                RGBA[] scan = _buffer.scanline(y);

                for (size_t x = 0; x < scan.length; ++x)
                    scan[x] = blendColor(clearColor, scan[x], clearColor.a);
            }
        }
        _canvas.initialize(_buffer.toRef());
        *canvas = &_canvas;
        *framebuffer = _buffer.toRef();
    }

    void fillWithClearColor(RGBA clearColor)
    {
        // Clear buffer with clear color, even if alpha isn't 255
        for (int y = 0; y < _lastKnownHeight; ++y)
        {
            RGBA[] scan = _buffer.scanline(y);
            scan[0.._lastKnownWidth] = clearColor; 
        }
    }

    override void getFrameSize(int* width, int* height)
    {
        *width = _lastKnownWidth;
        *height = _lastKnownHeight;
    }

    /// Mark end of drawing.
    void endFrame()
    {
        // Doesn't seem useful to clear that!
        //SDL_SetRenderDrawColor( _renderer, 0xff, 0x00, 0xff, 0x00 );
        //SDL_RenderClear(_renderer);

        // Update texture

        void* pixels;
        int pitch;
        if (0 == SDL_LockTexture(_texture, null, &pixels, &pitch))
        {
            // copy pixels
            for (int y = 0; y < _lastKnownHeight; ++y)
            {
                RGBA* source = _buffer.scanlinePtr(y);
                ubyte* dest = (cast(ubyte*)pixels) + (y * pitch);
                memcpy(dest, source, RGBA.sizeof * _lastKnownWidth);
            }

            SDL_UnlockTexture(_texture);
        }

        SDL_RenderCopy(_renderer, _texture, null, null);
        SDL_RenderPresent(_renderer);
    }

private:
    SDL_Window* _window;
    SDL_Renderer* _renderer;
    SDL_Texture* _texture;
    Canvas _canvas;
    OwnedImage!RGBA _buffer;    

    int _lastKnownWidth = 0;
    int _lastKnownHeight = 0;

    bool _isFullscreen = false;

    void toggleFullscreen()
    {
        _isFullscreen = !_isFullscreen;
        if (_isFullscreen)
        {
            SDL_SetWindowFullscreen(_window, SDL_WINDOW_FULLSCREEN_DESKTOP);
        }
        else
        {
            SDL_SetWindowFullscreen(_window, cast(SDL_WindowFlags)0);
        }
    }

    version(Windows)
    {
        extern(Windows) 
        {
            alias SetProcessDPIAware_t = int function();
        }
        HMODULE user32_module_;
        SetProcessDPIAware_t SetProcessDPIAware_;
    }

    void loadSDLLibrary()
    {
        SDLSupport ret = loadSDL();
        if(ret != sdlSupport) {

            if(ret == SDLSupport.noLibrary) {
                throw new Exception("SDL shared library failed to load.");
            }
            else if(SDLSupport.badLibrary) {
                if ( loadedSDLVersion() <= SDLSupport.sdl2010 )
                {
                    throw new Exception("SDL One or more symbols failed to load.");
                }
            }
        }
    }

    version(Windows)
    {
        void makeProcessDPIAware()
        {
            if ((user32_module_ = LoadLibraryA("User32.dll")) != null) 
            {
                SetProcessDPIAware_ = cast(SetProcessDPIAware_t) GetProcAddress(user32_module_, "SetProcessDPIAware".ptr);

                // call it
                SetProcessDPIAware_();
            }
        }
    }
    else
    {
        void makeProcessDPIAware()
        {
        }
    }
}







