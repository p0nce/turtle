import turtle;

int main(string[] args)
{
    runGame(new CanvasComparisonExample);
    return 0;
}

// left: drawing with canvas
// right: drawing with canvasity

class CanvasComparisonExample : TurtleGame
{
    override void load()
    {
        setBackgroundColor( color("#ffffff") );
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;
        rotation += dt*0.08;
    }

    double rotation = 0;

    override void draw()
    {
        float W = windowWidth;
        float H = windowHeight;


        // Note: this example highlight
        // how different sucessive blending becomes when
        // the blending is or not gamma-aware.
        // Here colors are approximately match but can't help
        // the drift toward black of sRGB blending in dplug:canvas


        string[7] COLORS = [
            "rgba(0, 0, 0, 0.3)",
            "rgba(255, 0, 0, 0.3)",
            "rgba(0, 255, 0, 0.3)",
            "rgba(0, 0, 255, 0.3)",
            "rgba(255, 255, 0, 0.3)",
            "rgba(0, 255, 255, 0.3)",
            "rgba(255, 0, 255, 0.3)",
        ];

        // Note: because of gamma-aware blending, you need
        // more opacity to match dplug:canvas!
        string[7] COLORSity = [
            "rgba(0, 0, 0, 0.5)",
            "rgba(255, 0, 0, 0.5)",
            "rgba(0, 255, 0, 0.5)",
            "rgba(0, 0, 255, 0.5)",
            "rgba(255, 255, 0, 0.5)",
            "rgba(0, 255, 255, 0.5)",
            "rgba(255, 0, 255, 0.5)",
        ];

        with(canvas)
        {
            
            
            translate(W/3, H/2);
            scale(40, 40);

            foreach (n; 0..10)
            {
                fillStyle = COLORS[n % 7];
                scale(0.8,0.8);
                rotate(rotation);

                beginPath();
                    moveTo(-0.5, -1);
                    lineTo( 0, -30);
                    lineTo(+0.5, -1);
                    lineTo(+3,  0);
                    lineTo(+1, +1);
                    lineTo( 0, +3);
                    lineTo(-1, +1);
                    lineTo(-3,  0);
                closePath();
                fill();
            }
        }

        with(console)
        {
            cls;
            println("Left: dplug:canvas    Right: canvasity");
        }

        with(canvasity)
        {
            
            translate(2*W/3, H/2);
            scale(40, 40);
            

            foreach (n; 0..10)
            {
                fillStyle = COLORSity[n % 7];
                scale(0.8,0.8);
                rotate(rotation);

                beginPath();                
                    moveTo(-0.5, -1);
                    lineTo( 0, -30);
                    lineTo(+0.5, -1);
                    lineTo(+3,  0);
                    lineTo(+1, +1);
                    lineTo( 0, +3);
                    lineTo(-1, +1);
                    lineTo(-3,  0);
                closePath();
                fill();
            }
        }
    }
}