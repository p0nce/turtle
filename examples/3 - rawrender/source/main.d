import turtle;

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

        // Note: there is no difference between object-space and world-space.
        //       the camera is rotating around a model who have no matrix.
        RGBA rayMarch(vec3f rayOrigin, vec3f rayDirection)
        {
            int far = 20;
            RGBA result = RGBA(0, 0, 0, 0);
            for (int n = far; n >= 0; --n)
            {
                vec3f pos = rayOrigin + rayDirection * n;

                int ix = cast(int)(pos.x + 1);
                int iy = cast(int)(pos.y + 1);
                int iz = cast(int)(pos.z + 1);

                bool hit = true;
                if (ix <= 0) hit = false;
                else if (iy <= 0) hit = false;
                else if (iz <= 0) hit = false;
                ix -= 1;
                iy -= 1;
                iz -= 1;
                if (ix >= _model.width) hit = false;
                else if (iy >= _model.height) hit = false;
                else if (iz >= _model.depth) hit = false;
                if (!hit)
                    continue;

                VoxColor color = _model.voxel(ix, iy, iz);
                RGBA rgba = RGBA(color.r, color.g, color.b, color.a);
                result = blendColor(rgba, result, rgba.a);
            }
            return result;
        }

        // Compute camera rays
        
        vec3f target = vec3f(_model.width*0.5f, _model.height*0.5f, _model.depth*0.5f);
        vec3f eye    = target + vec3f(sin(elapsedTime)*15.0f, -cos(elapsedTime)*15.0f, 0.0f);
        vec3f up     = vec3f(0, 0.0f, 1.0f);
        vec3f right  = vec3f(1.0f, 0.0f, 0.0f);

        vec3f camZ = (eye - target).normalized();
        vec3f camX = cross(-up, camZ).normalized();
        vec3f camY = cross(camZ, -camX);

        for (int y = 0; y < H; ++y)
        {
            RGBA[] scan = framebuf.scanline(y);

            for (int x = 0; x < W; ++x)
            {
                float dx = (x - (W-1)*0.5f) / (W*0.5f);
                float dy = (y - (H-1)*0.5f) / (H*0.5f);

                Ray ray;
                ray.orig = eye;
                ray.dir = (-camZ + camX * dx - camY * dy).normalized;

                float t;
                vec3i hitIndex;
                RGBA pixelColor = RGBA(0, 0, 0, 0);
                if (intersectVOX(ray, &_model, t, hitIndex))
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
}



