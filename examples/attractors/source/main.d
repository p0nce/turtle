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


    Xorshift128 random;

    ParticleSystem particles;
    particles.initialize(1000, 0);
    
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

        particles.computeGravity();
        particles.update(dt);


        IRenderer renderer = graphics.getRenderer();

        {
            Canvas* canvas = renderer.beginFrame(RGBA(16, 16, 16, 255));
            int width, height;
            renderer.getFrameSize(&width, &height);

            // display framerate
            canvas.fillStyle = "rgba(128, 0, 0, 128)";
            canvas.beginPath();
            float dx = 10 + dt * 10000;
            canvas.moveTo(10, 10);
            canvas.lineTo(dx, 10);
            canvas.lineTo(dx, 20);
            canvas.lineTo(10, 20);
            canvas.closePath();
            canvas.fill();

            canvas.translate(width*0.5, height*0.5);
            canvas.scale(0.5f,0.5f);

            RGBA[8] colors = [
                RGBA(255, 128, 0, 192),
                RGBA(0, 128, 255, 192),
                RGBA(0, 255, 0, 255),
                RGBA(0, 255, 255, 128),

                RGBA(255, 0, 0, 128),
                RGBA(255, 0, 255, 128),
                RGBA(255, 255, 0, 128),
                RGBA(255, 255, 255, 128)
                ];

    
            foreach(color; 0..8)
            {
                canvas.fillStyle = colors[color];

                canvas.beginPath();  
                   
                for (int n = 0; n < particles.count; ++n)
                {
                    if (particles.color[n] == color)
                    {
                        float x = particles.posx[n];
                        float y = particles.posy[n];
                        float velx = particles.velx[n] * dt * 4;
                        float vely = particles.vely[n] * dt * 4;    
                        vec2f vel = vec2f(particles.velx[n], particles.vely[n]);
                        vel.fastNormalize();
                        vel *= 1.0f;
                        canvas.moveTo(x + velx  * 1.0f, y + vely  * 1.0f);
                        canvas.lineTo(x - vel.y * 0.5f, y + vel.x * 0.5f);
                        canvas.lineTo(x - velx  * 1.0f, y - vely  * 1.0f);
                        canvas.lineTo(x + vel.y * 0.5f, y - vel.x * 0.5f);
                        canvas.lineTo(x + velx  * 1.0f, y + vely  * 1.0f);
                    }
                
                } 
                canvas.fill();
            }

            renderer.endFrame();
        }
    }  
    return 0;
}

struct ParticleSystem
{    
    int count;

    float[] posx;
    float[] posy;
    float[] velx;
    float[] vely;
    float[] accx;
    float[] accy;
    int[] color;

    void initialize(float  posstddev, float velstddev)
    {
        count = 1000;
        posx.reallocBuffer(count);
        posy.reallocBuffer(count);
        velx.reallocBuffer(count);
        vely.reallocBuffer(count);
        accx.reallocBuffer(count);
        accy.reallocBuffer(count);
        color.reallocBuffer(count);

        for(int n = 0; n < count; ++n)
        {
            posx[n] = randNormal() * posstddev;
            posy[n] = randNormal() * posstddev;
            velx[n] = randNormal() * velstddev;
            vely[n] = randNormal() * velstddev;
            accx[n] = 0.0f; 
            accy[n] = 0.0f;
            color[n] = uniform(0, 3);
            if (color[n] == 0)
                posx[n] += 500;
            else if (color[n] == 1)
                posy[n] += 500;
            else if (color[n] == 2)
            {
                posx[n] -= 300;
                posy[n] -= 380;
            }
        }
    }

    void computeGravity()
    {
        accx[0..count] = 0.0f;
        accy[0..count] = 0.0f;
        for(int n = 0; n < count; ++n)
        {
            for(int m = 0; m < count; ++m)
            {
                if (m != n)
                {
//                    bool pierrefeuilleciseau = ((color[n] + 1) % 3 == color[m]);

                    int mod = (3 + color[m] - color[n]) % 3;
                    float G = 0.0f;
                    if (mod == 0) G = 500.0f;
                    if (mod == 1) G = 0.0f;
                    if (mod == 2) G = -500.0f;
                   // float G = pierrefeuilleciseau ? 500.0f : 0.0f;                    
                    {
                        float dx = posx[n] - posx[m];
                        float dy = posy[n] - posy[m];
                        float d2 = 0.1f + sqrt(dx*dx + dy*dy);
                        
                        float ax = G * dx / (d2*d2);
                        float ay = G * dy / (d2*d2);
         /*               if (mod == 1)
                        {
                            accx[n] += ay;
                            accy[n] -= ax;
                        }
                 /*       else if (mod == 2)
                        {
                            accx[n] -= ay;
                            accy[n] += ax;
                        }
                        else*/
                        {
                            accx[n] -= ax;
                            accy[n] -= ay;
                        }
                        //accx[m] += ax;
                        //accy[m] += ay;
                    }
                }
            }
        }
    }

    void update(float dt)
    {
        velx[] += dt * accx[];
        vely[] += dt * accy[];
        posx[] += dt * velx[];
        posy[] += dt * vely[];
        velx[] *= 0.999f;
        vely[] *= 0.999f;

        for (int n = 0; n < count; ++n)
        {
            while (posx[n] < -1600) posx[n] += 3200;
            while (posx[n] > +1600) posx[n] -= 3200;
            while (posy[n] < -900) posy[n] += 1800;
            while (posy[n] > +900) posy[n] -= 1800;
        }
    }

    ~this()
    {
        posx.reallocBuffer(0);
        posy.reallocBuffer(0);
        velx.reallocBuffer(0);
        vely.reallocBuffer(0);
        accx.reallocBuffer(0);
        accy.reallocBuffer(0);
    }
}
