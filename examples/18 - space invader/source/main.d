import turtle;
import textmode;
import std;


class SpaceInvadersExample : TurtleGame
{
    int playerX;
    int playerY;
    int[] invaderX = [4, 10, 13, 15, 17, 20, 26];
    int invaderY = 2;
    int bulletX = -1;
    int bulletY = -1;
    int invaderDirection = 1; // New variable to track invader movement direction
    double invaderMoveTimer = 0; // New variable to control invader movement speed
    bool gameOver = false;
    double timeDiv = 0.5; 
    int level = 1;
    int score = 0;

    int[] enemyPattern()
    {
        switch(randInt(0, 3))
        {
            case 0: return [4, 10, 13, 15, 17, 20, 26];
            case 1: return [5, 10, 15, 20, 25];
            case 2: default:
                return [7,10,12,14, 15,16,18, 20,22];
        }
    }

    void nextLevel()
    {
        playerX = 15;
        playerY = 21;
        invaderY = randInt(2, 4);
        invaderX = enemyPattern();
        bulletX = -1;
        bulletY = -1;
        invaderMoveTimer = 0;
    }

    override void load()
    {
        nextLevel();
        setBackgroundColor(color("#000000"));

        TM_Options opt;
        opt.blurScale = 2.0f;
        opt.blurAmount = 2.0f;
        console.options(opt);
        console.size(30, 22);
        console.palette(TM_Palette.tango);
    }

    override void update(double dt)
    {
        console.update(dt);
        if (keyboard.isDown("left") && playerX > 0) playerX--;
        if (keyboard.isDown("right") && playerX < 28) playerX++;
        if (keyboard.isDown("up") && playerY > 17) playerY--;
        if (keyboard.isDown("down") && playerY < 21) playerY++;
        if (keyboard.isDown("space") && bulletY == -1) 
        {
            bulletY = playerY;
            bulletX = playerX;
        }

        if (bulletY > -1) bulletY--;

        if (bulletY >= invaderY && bulletY < invaderY + 1)
        {
            foreach (ref x; invaderX)
            {
                if (x == bulletX)
                {
                    score ++;
                    x = -1; // Remove hit invader
                    bulletY = -1;
                    break;
                }
            }
        }

         // Move invaders
        invaderMoveTimer += dt;
        if (invaderMoveTimer >= timeDiv) // Move invaders every 0.5 seconds
        {
            invaderMoveTimer -= timeDiv;
            if (invaderMoveTimer > 0.5) invaderMoveTimer = 0.5;
            bool changeDirection = false;

            foreach (ref x; invaderX)
            {
                if (x != -1)
                {
                    x += invaderDirection;
                    if (x <= 0 || x >= 28) // Check if invaders reached screen edges
                    {
                        changeDirection = true;
                    }
                }
            }

            if (changeDirection)
            {
                invaderDirection *= -1; // Reverse direction
                invaderY++; // Move invaders down
            }
        }

        // Check for fail conditions
        if (invaderY >= 21 && invaderX.any!(x => x != -1))
        {
            gameOver = true;
        }

        if (!invaderX.any!(x => x != -1))
        {
            level = level + 1;
            timeDiv = timeDiv * 0.8;
            nextLevel();
        }

        if (keyboard.isDown("escape")) exitGame();
        if (gameOver)
        {
            if (keyboard.isDown("space")) 
            {
                level = 1;
                timeDiv = 0.5;
                gameOver = false;
                score = 0;
                nextLevel();
            }
            return;
        }
    }

    override void draw()
    {
        ImageRef!RGBA fb = framebuffer();

        with (console)
        {
            cls();

            // Draw player
            locate(playerX, playerY);
            fg(TM_green);
            cprint("<shiny><bold>A</></>");

            // Draw invaders
            fg(TM_red);
            foreach (x; invaderX)
            {
                if (x != -1)
                {
                    locate(x, invaderY);
                    cprint("W");
                }
            }

            // Draw bullet
            if (bulletY > -1)
            {
                locate(bulletX, bulletY);
                fg(TM_yellow);
                cprint("<shiny>|</shiny>");
            }

            if (gameOver)
            {
                // Display game over message
                locate(10, 10);
                fg(TM_red);
                print("GAME OVER");
                locate(3, 12);
                fg(TM_white);
                print("Press SPACE to RESTART");
            }
            else
            {
                // Draw score and level
                locate(0, 0);
                fg(TM_white);
                print("Level: ");
                fg(TM_cyan);
                print(level.to!string);
                locate(0, 1);
                fg(TM_white);
                print("Score: ");
                fg(TM_cyan);
                print(score.to!string);
            }
        }
    }
}

int main(string[] args)
{
    runGame(new SpaceInvadersExample());
    return 0;
}