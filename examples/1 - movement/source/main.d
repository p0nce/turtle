import turtle;

int main(string[] args)
{
    runGame(new MovementExample);
    return 0;
}

class MovementExample : TurtleGame
{
    float posx = 0;
    float posy = 0;

    override void load()
    {
        // Having a clear color with an alpha value different from 255 
        // will result in a cheap motion blur.
        setBackgroundColor( color("rgba(0, 0, 0, 10%)") );
    }

    override void update(double dt)
    {
        float SPEED = 10;
        if (keyboard.isDown("left")) posx -= SPEED * dt;
        if (keyboard.isDown("right")) posx += SPEED * dt;
        if (keyboard.isDown("up")) posy -= SPEED * dt;
        if (keyboard.isDown("down")) posy += SPEED * dt;
        if (keyboard.isDown("escape")) exitGame;
    }

    override void draw()
    {
        with(canvas)
        {
            save();

            translate(windowWidth/2, windowHeight/2);
            float zoom = 50.0f * (windowHeight / 720);
            scale(zoom, zoom);
            translate(posx, posy);
            fillStyle = rgba(255, 0, 0, 1.0);

            beginPath();
                moveTo(-1, -1);
                lineTo(+1, -1);
                lineTo(+1, +1);
                lineTo(-1, +1);
                fill(); // path is auto-closed by `fill()`
            restore();
        }
    }
}