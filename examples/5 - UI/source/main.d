import turtle;

int main(string[] args)
{
    runGame(new UIExample);
    return 0;
}

class UIExample : TurtleGame
{
    float posx = 0;
    float posy = 0;

    override void load()
    {
        setBackgroundColor( color("#2d2d30") );
        setTitle("UI example");
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape"))
        {
            exitGame;
        }
    }

    override void resized(float width, float height)
    {
    }

    override void mouseMoved(float x, float y, float dx, float dy)
    {
    }

    override void mousePressed(float x, float y, MouseButton button, int repeat)
    {
    }

    override void mouseWheel(float wheelX, float wheelY)
    {
    }

    override void mouseReleased(float x, float y, MouseButton butto)
    {
    }

    override void gui()
    {
    }

    override void draw()
    {
    }
}

