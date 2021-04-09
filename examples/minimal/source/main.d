module main;

import turtle;
import std.math;
import std.stdio;
import dplug.core;
import std.random;

import bindbc.sdl;

int main(string[] args)
{
    IGraphics graphics = createGraphics();
    scope(exit) destroy(graphics);

    uint ticks = graphics.getTicks(); 

    bool finished = false;

    while(!finished)
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
                {
                    if (event.key.keysym.sym == SDLK_ESCAPE)
                    {
                        return 0;
                    }
                    break;
                }

                case SDL_QUIT:
                    return 0;

                default: break;
            }
        }

        uint now = graphics.getTicks();
        uint ticksDiff = now - ticks;
        ticks = now;
        double time = now * 0.001;
        double dt = ticksDiff * 0.001;

        IRenderer renderer = graphics.getRenderer();

        {
            Canvas* canvas = renderer.beginFrame(RGBA(106, 0, 53, 255));
            int width, height;
            renderer.getFrameSize(&width, &height);
    
            float W = width;
            float H = height;

            foreach(layer; 0..8)
            {
                canvas.save();

                canvas.translate(W / 2, H / 2);
                float zoom = H/4 * (1.0 - layer / 7.0) ^^ (1.0 + 0.2 * cos(time));
                canvas.scale(zoom, zoom);
                canvas.rotate(layer + time * (0.5 + layer * 0.1));
                canvas.fillStyle = RGBA(cast(ubyte)(255 - layer * 32), 
                                        cast(ubyte)(64 + cast(ubyte)(layer * 16)), 128, 255);

                canvas.beginPath();                
                    canvas.moveTo(-1, -1);
                    canvas.lineTo( 0, -3);
                    canvas.lineTo(+1, -1);
                    canvas.lineTo(+3,  0);
                    canvas.lineTo(+1, +1);
                    canvas.lineTo( 0, +3);
                    canvas.lineTo(-1, +1);
                    canvas.lineTo(-3,  0);
                canvas.closePath();
                canvas.fill();

                canvas.restore();
            }

            renderer.endFrame();
        }
    }  
    return 0;
}
