import turtle;

import dplug.core;
import dplug.graphics;
import voxd;
import ray;

int main(string[] args)
{
    runGame(new RawRenderExample);
    return 0;
}

class RawRenderExample : TurtleGame
{
    override void load()
    {
        setBackgroundColor( color("black") );
        _model = decodeVOXFromFile("chr_knight.vox");
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;

        angleX = 1.0f;
        angleZ += dt;

        float W = windowWidth;
        float H = windowHeight;
    }

    override void draw()
    {
        ImageRef!RGBA framebuf = framebuffer();
        int W = framebuf.w;
        int H = framebuf.h;

        // Compute camera rays
        
        Vector3 target = Vector3(_model.width*0.5f, _model.height*0.5f, _model.depth*0.5f);

        
        float Z = sin(elapsedTime * 0.3f) * 3.0f;
        Vector3 eye    = target + Vector3(sin(elapsedTime)*15.0f, -cos(elapsedTime)*15.0f, Z);
        Vector3 up     = Vector3(0.0f, 0.0f, 1.0f);
        Vector3 right  = Vector3(1.0f, 0.0f, 0.0f);

        Vector3 camZ = (eye - target).normalized();
        Vector3 camX = -up.cross(camZ).normalized();
        Vector3 camY = camZ.cross(-camX);

        for (int y = 0; y < H; ++y)
        {
            RGBA[] scan = framebuf.scanline(y);

            for (int x = 0; x < W; ++x)
            {
                float ar = cast(float)W / H;
                float dx = (x - (W-1) * 0.5f) / (W * 0.5f);
                float dy = (y - (H-1) * 0.5f) / (H * 0.5f);

                Vector3 dir = (-camZ + camX * dx * ar - camY * dy).normalized();
                
                Ray ray;
                ray.orig = vec3f(eye.x, eye.y, eye.z);
                ray.dir  = vec3f(dir.x, dir.y, dir.z);

                float t;
                vec3i hitIndex;
                RGBA pixelColor = RGBA(0, 0, 0, 0);
                if (intersectVOX(ray, &_model, t, hitIndex, _visitedVoxelsBuffer))
                {
                    VoxColor c = _model.voxel( hitIndex.x, hitIndex.y, hitIndex.z );
                    pixelColor = RGBA(c.r, c.g, c.b, c.a);                    
                }
                scan[x] = pixelColor;
            }
        }
    }        

private:
    float angleX = 0;
    float angleZ = 0;
    VOX _model;

    Vec!vec3i _visitedVoxelsBuffer;
}



