import turtle;
import world;
import biomes;

int main(string[] args)
{
    runGame(new LaserWorldExample);
    return 0;
}

class LaserWorldExample : TurtleGame
{
    enum WX = 128;
    enum WY = 128;

    enum GX = 25;
    enum GY = 25;



    bool playing = false;
    double timeAccum = 0.0;
    bool selected;
    int selectedX;
    int selectedY;
    World world;

    int CX = 0;
    int CY = 0;

    override void load()
    {
        setBackgroundColor( RGBA(32, 32, 32, 255) );
        console.size(GX, GY);
        console.palette(TM_Palette.tango);
        uint seed;
        createWorld(seed);
    }

    void createWorld(uint seed)
    {   
        world = new World(seed);
    }

    override void update(double dt)
    {     
        if (keyboard.isDown("escape")) exitGame;
        if (keyboard.isDown("up")) CY -= 1;
        if (keyboard.isDown("down")) CY += 1;
        if (keyboard.isDown("left")) CX -= 1;
        if (keyboard.isDown("right")) CX += 1;
    }
    // Note: this use both the canvas and direct frame buffer access (for text)
    override void draw()
    {
        console.cls();
        for (int y = 0; y < GY; ++y)
        {
            for (int x = 0; x < GX; ++x)
            {
                auto biome = world.biomeAt(x + CX, y + CY);
                console.locate(x, y);
                console.cprint(biomeGraphics(biome));
            }
        }
    }

    override void mouseMoved(float x, float y, float dx, float dy)
    {   
        doMouse(x, y);
    }

    override void mousePressed(float x, float y, MouseButton button, int repeat)
    {
        doMouse(x, y);
    }

    void doMouse(float x, float y)
    {
    }

}

