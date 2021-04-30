import turtle;

import dplug.graphics;
import voxd;

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


        vec3f eye    = vec3f(0, 0, 10.0f);
        vec3f target = vec3f(0, 0, 0.0f);
        vec3f up     = vec3f(0, 1.0f, 0.0f);
        vec3f right  = vec3f(1.0f, 0.0f, 0.0f);

        for (int y = 0; y < H; ++y)
        {
            for (int x = 0; x < W; ++x)
            {
                float dx = (x - (W-1)*0.5f) / (W*0.5f);
                float dy = (y - (H-1)*0.5f) / (H*0.5f);
                vec3f rayOrigin = eye;
                vec3f rayDirection = (target - eye) + 20 * dx * right + 20 * dy * -up;
                rayDirection.normalize();







            }
        }
    }        

private:
    float angleX = 0;
    float angleZ = 0;

    VOX _model;
}

