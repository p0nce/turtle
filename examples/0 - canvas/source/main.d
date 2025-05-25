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

    override void gui()
    {
        with (ui)
        {
            if (beginWindow("Tweak", rectangle(10, 10, 410, 280)))
            {
                slider(&rBase, 0, 255);
                slider(&gBase, 0, 255);
                slider(&bBase, 0, 255);

                if (button("Exit")) exitGame;
                endWindow;
            }
        }
    }

    double rBase = 255;
    double gBase = 64;
    double bBase = 128;

    override void draw()
    {
        foreach(layer; 0..8)
            with(canvas)
            {
                save();

                translate(windowWidth / 2, windowHeight / 2);
                float zoom = windowHeight/4 * (1.0 - layer / 7.0) ^^ (1.0 + 0.2 * cos(elapsedTime));
                scale(zoom, zoom);

                save;
                    rotate(layer + elapsedTime * (0.5 + layer * 0.1));

                    auto gradient = createCircularGradient(0, 0, 3);

                    double r = rBase - layer * 32;
                    double g = gBase + layer * 16;
                    double b = bBase;
                    gradient.addColorStop(0, rgba(r, g, b, 1.0));
                    gradient.addColorStop(1, rgba(r/2, g/3, b/2, 1.0));

                    fillStyle = gradient;

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
                restore;

                canvas.globalCompositeOperation = (layer%2) ? CompositeOperation.add : CompositeOperation.subtract;
                rotate(- elapsedTime * (0.5 + layer * 0.1));
                fillStyle = rgba((128^layer)&255, 128>>layer, 128, 0.25);
                beginPath();
                    moveTo(-0.2, -15);
                    lineTo(+0.2, -15);
                    lineTo(+0.2, +15);
                    lineTo(-0.2, +15);
                    closePath();
                fill();

                restore();
            }
    }
}