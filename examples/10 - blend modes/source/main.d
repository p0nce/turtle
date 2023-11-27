import turtle;

int main(string[] args)
{
    runGame(new BlendModesExample);
    return 0;
}

class BlendModesExample : TurtleGame
{
    override void load()
    {
        setBackgroundColor( color("#888") );
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;
    }

    override void draw()
    {
        with(canvas)
        {
            save();

            float dx = sin(elapsedTime)*20;
            float dy = cos(elapsedTime)*20;


            void drawing(float x, float y, CompositeOperation op)
            {
                save;
                translate(x, y);

                float W = 200;
                float H = 200;

                // Draw a background.
                canvas.globalCompositeOperation = CompositeOperation.sourceOver;
                canvas.fillStyle = "#444";
                canvas.fillRect(0, 0, W, H);

                canvas.fillStyle = "green";
                canvas.beginPath();
                    canvas.moveTo(25, 25);
                    canvas.lineTo(185, 25);
                    canvas.lineTo(25, 185);
                    canvas.fill();

                canvas.fillStyle = "blue";
                canvas.fillRect(100, 20, 80, 80);

                canvas.fillStyle = "red";

                canvas.fillCircle(150, 150, 50);

                canvas.globalCompositeOperation = op;
                translate(dx, dy);

                auto grad = canvas.createCircularGradient(W/2, H/2, W/2);
                grad.addColorStop(0.0, RGBA(255, 255, 255, 255));
                grad.addColorStop(0.1, RGBA(255, 0, 0, 255));
                grad.addColorStop(0.2, RGBA(0, 255, 0, 255));
                grad.addColorStop(0.3, RGBA(0, 0, 255, 255));
                grad.addColorStop(0.4, RGBA(255, 0, 0, 128));
                grad.addColorStop(0.5, RGBA(0, 255, 0, 128));
                grad.addColorStop(0.6, RGBA(0, 0, 255, 128));
                grad.addColorStop(0.7, RGBA(255, 0, 0, 64));
                grad.addColorStop(0.8, RGBA(0, 255, 0, 64));
                grad.addColorStop(0.9, RGBA(0, 0, 255, 64));
                grad.addColorStop(1.0, RGBA(0, 0, 255, 0));

                canvas.fillStyle = grad;
                canvas.fillCircle(W/2, H/2, W/2);
                restore;
            }

            

            drawing(0, 0, CompositeOperation.sourceOver);
            drawing(250, 0, CompositeOperation.lighter);
            drawing(500, 0, CompositeOperation.subtract);
            drawing(250, 250, CompositeOperation.lighten);
            drawing(500, 250, CompositeOperation.darken);
            restore();
        }
    }
}