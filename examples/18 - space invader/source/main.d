import turtle;
import textmode;
import std;

// Note: generated with Cursor, I had almost nothing to change


class SpaceInvadersExample : TurtleGame
{
    int playerX = 20;
    int[] invaderX = [5, 10, 15, 20, 25, 30, 35];
    int invaderY = 2;
    int bulletX = -1;
    int bulletY = -1;

    override void load()
    {
        setBackgroundColor(color("#000000"));
        console.size(40, 22);
        console.palette(TM_Palette.tango);
    }

    override void update(double dt)
    {
        console.update(dt);
        if (keyboard.isDown("left") && playerX > 0) playerX--;
        if (keyboard.isDown("right") && playerX < 39) playerX++;
        if (keyboard.isDown("space") && bulletY == -1) 
        {
            bulletY = 20;
            bulletX = playerX;
        }

        if (bulletY > -1) bulletY--;

        if (bulletY >= invaderY && bulletY < invaderY + 1)
        {
            foreach (ref x; invaderX)
            {
                if (x == bulletX)
                {
                    x = -1; // Remove hit invader
                    bulletY = -1;
                    break;
                }
            }
        }

        if (keyboard.isDown("escape")) exitGame();
    }

    override void draw()
    {
        ImageRef!RGBA fb = framebuffer();

        with (console)
        {
            cls();

            // Draw player
            locate(playerX, 21);
            fg(TM_green);
            print("A");

            // Draw invaders
            fg(TM_red);
            foreach (x; invaderX)
            {
                if (x != -1)
                {
                    locate(x, invaderY);
                    cprint("<shiny>W</shiny>");
                }
            }

            // Draw bullet
            if (bulletY > -1)
            {
                locate(bulletX, bulletY);
                fg(TM_yellow);
                cprint("<shiny>|</shiny>");
            }

            // Draw score
            locate(0, 0);
            fg(TM_white);
            print("Score: ");
            fg(TM_cyan);
            print(invaderX.count(-1).to!string);
        }
    }
}

int main(string[] args)
{
    runGame(new SpaceInvadersExample());
    return 0;
}