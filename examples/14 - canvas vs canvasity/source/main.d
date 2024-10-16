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
        rotation += dt*0.05;
    }

    double rotation = 0;

    override void draw()
    {
        float W = windowWidth;
        float H = windowHeight;
        with(canvas)
        {
            fillStyle = "rgba(0, 0, 0, 0.3)";
            
            translate(W/3, H/2);
            scale(40, 40);

            foreach (n; 0..4)
            {
                scale(0.7,0.7);
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

        with(canvasity)
        {
            // Note: because of gamma-aware blending, you need 2x
            // more opacity to match dplug:canvas!
            fillStyle = "rgba(0, 0, 0, 0.5)";

            translate(2*W/3, H/2);
            scale(40, 40);
            

            foreach (n; 0..4)
            {
                scale(0.7,0.7);
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