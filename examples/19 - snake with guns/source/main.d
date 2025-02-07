import turtle;
import textmode;
import std;


class SnakeExample : TurtleGame
{
    override void load()
    {
        setBackgroundColor(color("##EAF5FF"));

        TM_Options opt;
        console.size(30, 22);
        console.palette(TM_paletteTango);
    }

    override void update(double dt)
    {
        console.update(dt);
        if (keyboard.isDownOnce("escape")) exitGame();
        
    }

    override void draw()
    {
        ImageRef!RGBA fb = framebuffer();

    }
}

int main(string[] args)
{
    runGame(new SnakeExample());
    return 0;
}