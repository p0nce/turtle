import turtle;

int main(string[] args)
{
    runGame(new CellAutomatonExample);
    return 0;
}

class CellAutomatonExample : TurtleGame
{
    enum GX = 30;
    enum GY = 24;

    alias Grid = bool[GX][GY];

    Grid grid; // current grid state

    bool playing = false;
    double timeAccum = 0.0;
    bool selected;
    int selectedX;
    int selectedY;

    override void load()
    {
        setBackgroundColor( RGBA(32, 32, 32, 255) );
        console.size(GX, GY);
        console.palette(TM_Palette.tango);
        makeNewGrid();
    }

    void makeNewGrid()
    {
        float INITIAL_DENSITY = 25;
        for (int y = 0; y < GY; ++y)
        {
            for (int x = 0; x < GX; ++x)
            {
                grid[y][x] = randInt(0, 100) < INITIAL_DENSITY;
            }
        }
    }

    override void update(double dt)
    {     
        if (keyboard.isDownOnce("return"))
        {
            makeNewGrid;
            playing = false;
        }
        if (keyboard.isDownOnce("space"))
            playing = !playing;

        if (keyboard.isDown("escape")) exitGame;

        if (playing)
        {
            timeAccum += dt;
            if (timeAccum > 0.3)
            {
                timeAccum = 0.0;
                nextGen();
            }
        }
    }

    void nextGen()
    {
        int[GX][GY] neigh;
        // compute number of neighbours
        for (int y = 0; y < GY; ++y)
        {
            for (int x = 0; x < GX; ++x)
            {
                neigh[y][x] = 0; // don't count self
                for (int k  =-1; k <= 1; ++k)
                    for (int l  =-1; l <= 1; ++l)
                        if (l != 0 || k != 0)
                        {
                            int dx = (x + k + GX) % GX;
                            int dy = (y + l + GY) % GY;
                            assert (dx >= 0 && dx < GX && dy >= 0 && dy < GY);
                        
                            if (grid[dy][dx])
                                neigh[y][x]++;
                        }
            }
        }

        // Normal game of life
        for (int y = 0; y < GY; ++y)
        {
            for (int x = 0; x < GX; ++x)
            {
                int n = neigh[y][x];
                if (n < 2)
                    grid[y][x] = false;
                else if (n == 3)
                    grid[y][x] = true;
                else if (n > 3)
                    grid[y][x] = false;
            }
        }
    }

    // Note: this use both the canvas and direct frame buffer access (for text)
    override void draw()
    {
        console.cls();


        for (int y = 0; y < GY; ++y)
        {
            for (int x = 0; x < GX; ++x)
            {
                bool on = grid[y][x];
                console.locate(x, y);
                if (selected && x == selectedX && y == selectedY)
                {
                    if (on)
                        console.cprint("<on_grey> </on_grey>");
                    else
                        console.cprint("<on_yellow> </on_yellow>");
                }
                else
                {
                    if (on)
                        console.cprint("<on_lblue> </on_lblue>");
                    else
                        console.cprint("<on_black> </on_black>");
                }
            }
        }

        console.locate(0, 0);
        console.fg(TM_black);
        console.bg(TM_white);
        console.cprintln("Click LEFT to put cells    ");
        console.cprintln("Click RIGHT to remove cells");
        console.cprintln("Press SPACE to play/stop   ");
        console.cprintln("Press RETURN to regenerate ");
    }

    override void mouseMoved(float x, float y, float dx, float dy)
    {   
        doMouse(x, y);
    }

    override void mousePressed(float x, float y, MouseButton button, int repeat)
    {
        doMouse(x, y);
    }

    void doMouse(float x, float y)
    {
        selected = console.hit(x, y, &selectedX, &selectedY);
        if (selected && mouse.left)
            grid[selectedY][selectedX] = true;
        if (selected && mouse.right)
            grid[selectedY][selectedX] = false;
    }

}

