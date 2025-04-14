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
{
    import bindbc.sdl;
    import bindbc.loader;
}

import turtle.renderer;
import dplug.graphics;
import gamut;
import canvasity;

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

    // Return SDL Window ID
    uint getWindowID();

    // return a SDL_Window* for further SDL calls
    void* getWindowObject(); 

    void setTitle(const(char)[] title);
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

        SDL_WindowFlags flags = SDL_WINDOW_RESIZABLE
                              | SDL_WINDOW_MOUSE_FOCUS
                              | SDL_WINDOW_INPUT_FOCUS;

        if (enableHIDPI)
            flags |= SDL_WINDOW_HIGH_PIXEL_DENSITY;

        _window = SDL_CreateWindow("", 1440, 1024, flags);

        if (RENDERER)
        {
            enum SDL_RENDERER_ACCELERATED = 0x00000002;
            enum SDL_RENDERER_PRESENTVSYNC = 0x00000004;

            // Let SDL choose
            _renderer = SDL_CreateRenderer(_window, null);

            // TODO: prefer accelerated and vsync?
            // Rate all available renderers?
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

    override void setTitle(const(char)[] title)
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
                case SDL_EVENT_KEY_DOWN:
                {
                    SDL_KeyboardEvent* key = &event.key;
                    if (key.key == SDLK_RETURN && ((key.mod & SDL_KMOD_ALT) != 0))
                        toggleFullscreen();
                    else if (key.key == SDLK_F11)
                        toggleFullscreen();
                    break;
                }
                case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:
                    // TODO is there anything to do here?
                    // should test with changing DPI
                    break;

                // "Window has been resized to data1xdata2"
                case SDL_EVENT_WINDOW_RESIZED: 
                {
                    uint windowID = getWindowID();
                    if (event.window.windowID != windowID)  
                        break;
                    int width = event.window.data1;
                    int height = event.window.data2;

                    if (RENDERER)
                    {
                        SDL_Rect r;
                        r.x = 0;
                        r.y = 0;
                        r.w = width;
                        r.h = height;
                        // failure ignored here
                        SDL_SetRenderViewport(_renderer, &r); 
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

    override void* getWindowObject()
    {
        return _window;
    }

    // IRenderer

    /// Start drawing, return a Canvas initialized to the drawing area.
    override void beginFrame(RGBA8 clearColor, 
                             Canvas** canvas, 
                             Canvasity** canvasity,
                             ImageRef!RGBA* framebuffer)
    {
 
        // Get size of window. TODO Failure ignored here.
        int w, h;
        SDL_GetRenderOutputSize(_renderer, &w, &h);

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
        else if (clearColor.a == 0)
        {
            // do nothing
        }
        else
        {
            // blend color with previous to make a cheap motion blur
            RGBA col = RGBA(clearColor.r, clearColor.g,
                            clearColor.b, clearColor.a);
            for (int y = 0; y < _lastKnownHeight; ++y)
            {
                RGBA[] scan = _buffer.scanline(y);

                for (size_t x = 0; x < scan.length; ++x)
                    scan[x] = blendColor(col, scan[x], col.a);
            }
        }

        // Initialize the canvases
        _canvas.initialize(_buffer.toRef());
        *canvas = &_canvas;

        {
            Image view;
            view.createView(_buffer.toRef().pixels, _buffer.w, _buffer.h, 
                            PixelType.rgba8, cast(int)_buffer.toRef().pitch);
            _canvasity.initialize(view);
            *canvasity = &_canvasity;
        }


        *framebuffer = _buffer.toRef();
    }

    void fillWithClearColor(RGBA8 clearColor)
    {
        // Clear buffer with clear color, even if alpha isn't 255
        RGBA col = RGBA(clearColor.r, clearColor.g,
                        clearColor.b, clearColor.a);
        for (int y = 0; y < _lastKnownHeight; ++y)
        {
            RGBA[] scan = _buffer.scanline(y);
          //  scan[0.._lastKnownWidth] = col; 

            memset32(&scan[0], *cast(int*)(&col), _lastKnownWidth);
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
        if (SDL_LockTexture(_texture, null, &pixels, &pitch))
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
        else
        {
            // TODO do something sensible
            return;
        }

        SDL_RenderTexture(_renderer, _texture, null, null);
        SDL_RenderPresent(_renderer);
    }

private:
    SDL_Window* _window;
    SDL_Renderer* _renderer;
    SDL_Texture* _texture;
    Canvas _canvas;
    Canvasity _canvasity;
    OwnedImage!RGBA _buffer; 

    int _lastKnownWidth = 0;
    int _lastKnownHeight = 0;

    bool _isFullscreen = false;

    static void memset32(void* dest, int value, size_t count)
    {
        int* buf = cast(int*) dest;
        while(count--) *buf++ = value;
    }

    void toggleFullscreen()
    {
        // fullscreen means "borderless full size window", not
        // exclusive mode.
        SDL_SetWindowFullscreenMode(_window, null);

        _isFullscreen = !_isFullscreen;
        if (_isFullscreen)
        {
            SDL_SetWindowFullscreen(_window, true);
        }
        else
        {
            SDL_SetWindowFullscreen(_window, false);
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
        LoadMsg ret = loadSDL();
        if(ret != LoadMsg.success)
        {
            /*
            Error handling. For most use cases, it's best to use the error handling API in
            BindBC-Loader to retrieve error messages for logging and then abort.
            If necessary, it's possible to determine the root cause via the return value:
            */
            if(ret == LoadMsg.noLibrary)
            {
                throw new Exception("The SDL shared library failed to load");
            } 
            else if(ret == LoadMsg.badLibrary)
            {
                throw new Exception("One or more symbols failed to load. The likely cause is that"~
                                    "the shared library is for a lower version than BindBC-SDL was"~
                                    "configured to load.");
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







