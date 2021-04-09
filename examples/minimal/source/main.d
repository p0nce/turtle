module main;

import turtle;

int main(string[] args)
{
    runGame(new Minimal);
    return 0;
}

class Minimal : TurtleGame
{
    override void load()
    {
        setBackgroundColor( color("#6A0035") );
    }

    override void draw()
    {
        foreach(layer; 0..8)
        {
            canvas.save();

                canvas.translate(windowWidth / 2, windowHeight / 2);
                float zoom = windowHeight/4 * (1.0 - layer / 7.0) ^^ (1.0 + 0.2 * cos(elapsedTime));
                canvas.scale(zoom, zoom);
                canvas.rotate(layer + elapsedTime * (0.5 + layer * 0.1));
                canvas.fillStyle = color( 255 - layer * 32, 64 + layer * 16, 128, 255);

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
    }
}