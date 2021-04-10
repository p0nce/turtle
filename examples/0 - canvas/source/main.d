import turtle;

int main(string[] args)
{
    runGame(new CanvasExample);
    return 0;
}

class CanvasExample : TurtleGame
{
    override void load()
    {
        setBackgroundColor( color("#6A0035") );
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;
    }

    override void draw()
    {
        foreach(layer; 0..8)
            with(canvas)
            {
                save();

                translate(windowWidth / 2, windowHeight / 2);
                float zoom = windowHeight/4 * (1.0 - layer / 7.0) ^^ (1.0 + 0.2 * cos(elapsedTime));
                scale(zoom, zoom);
                rotate(layer + elapsedTime * (0.5 + layer * 0.1));
                fillStyle = color( 255 - layer * 32, 64 + layer * 16, 128, 255);

                beginPath();
                    moveTo(-1, -1);
                    lineTo( 0, -3);
                    lineTo(+1, -1);
                    lineTo(+3,  0);
                    lineTo(+1, +1);
                    lineTo( 0, +3);
                    lineTo(-1, +1);
                    lineTo(-3,  0);
                closePath();
                fill();

                restore();
            }
    }
}