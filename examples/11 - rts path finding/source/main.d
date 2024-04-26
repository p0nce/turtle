import turtle;
import dosfont;

// A port of https://microstudio.dev/i/KimsGames/rtspathfinding/

int main(string[] args)
{
    runGame(new RTSPathFinding);
    return 0;
}

// dimensions
enum COLUMNS = 30;
enum ROWS = 30;

class RTSPathFinding : TurtleGame
{
    override void load()
    {
        setBackgroundColor( color("#000000") );
        grid = new Grid;
        grid.addUnit(2, 2);
        grid.addUnit(2, 3);
        grid.addUnit(3, 2);
        grid.addUnit(2, 4);
    }

    override void resized(float width, float height)
    {
        screenWidth = width;
        screenHeight = height;
        float minDim    = (width < height) ? width : height;
        float minMapDim = COLUMNS < ROWS ? COLUMNS : ROWS;

        grid.tileSize = (minDim / (minMapDim + 2));
        grid.offsetX = (screenWidth - grid.tileSize * COLUMNS) * 0.5f;
        grid.offsetY = (screenHeight - grid.tileSize * ROWS) * 0.5f;
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;
        if (keyboard.isDown("c")) grid.clearWorld;
        grid.update(keyboard, mouse, screenWidth, screenHeight);
    }

    override void draw()
    {
        grid.draw(canvas);

        auto frame = framebuffer;

        RGBA textCol = color("yellow");
        int y = cast(int)screenHeight - 96;
        drawDOSText(frame, DOSFontType.large8x16, "Hold mouse left to add wall", textCol, 16, y); y += 16;
        frame.drawDOSText(DOSFontType.large8x16, "Hold mouse right to remove wall", textCol, 16, y); y += 16;
        frame.drawDOSText(DOSFontType.large8x16, "Press C to clear all", textCol, 16, y); y += 16;
        frame.drawDOSText(DOSFontType.large8x16, "Press D to select destination", textCol, 16, y); y += 16;
        frame.drawDOSText(DOSFontType.large8x16, "Press U to create unit", textCol, 16, y); y += 16;
    }

    Grid grid;
    float screenWidth;
    float screenHeight;
}

class Unit
{
    Grid grid;
    int dir, step;
    int gridX, gridY;
    double x, y;
    string state;
    string command;

    enum HISTORY = 20;
    int[HISTORY] traveled; // grid locations traveled in last HISTORY moves
    int traveledIndex;

    this(Grid grid, int x, int y)
    {
        this.grid = grid;
        gridX = x;
        gridY = y;
        this.x = x;
        this.y = y;
        state = "idle";
        command = "none";
        dir = 0;
        step = 0;
        traveledIndex = 0;
        traveled[] = -1;
        grid.setBlock(x, y, 2);
    }

    void update()
    {
        cantGo();
        chooseDirection();
        walk();
    }

    void draw(Canvas* canvas)
    {        
        canvas.fillStyle = "#eda1ff";
        float rx = (grid.offsetX + x * grid.tileSize + grid.tileSize * 0.5f);
        float ry = (grid.offsetY + y * grid.tileSize + grid.tileSize * 0.5f);
        float rr = grid.tileSize * 0.35f;
        canvas.fillCircle(rx, ry, rr);
    }

    void cantGo()
    {
        if (command == "move" && grid.getPath(gridX, gridY) == -1)
            command = "none";
    }

    void chooseDirection()
    {
        if (command == "move" && state == "idle")
        {
            int bestDir = -1;
            int bestDist = 10000;

            // check all directions
            for (int i = 0; i < 8; ++i)
            {
                int nx = gridX + dirX[i];
                int ny = gridY + dirY[i];

                // skip wall and occupied cells
                if (grid.getBlock(nx, ny) != 0)
                    continue;

                // skip larger path distance
                int thisDist = grid.getPath(gridX, gridY);
                int newDist = grid.getPath(nx, ny);
                if (newDist > thisDist)
                    continue;

                // skip larger then bestDist
                if (newDist > bestDist)
                    continue;

                // skip already traveled
                {
                    bool found = false;
                    foreach(t; traveled)
                        if (t == nx + ny * COLUMNS)
                            found = true;
                    if (found) 
                        continue;
                }

                bestDist = newDist;
                bestDir = i;
            }
            
            // if found, start walking
            if (bestDir != -1)
            {
                dir = bestDir;
                step = dirD[dir];
                state = "walk";

                // move on grid
                grid.setBlock(gridX, gridY, 0);
                gridX += dirX[dir];
                gridY += dirY[dir];
                grid.setBlock(gridX, gridY, 2);

                // add to traveled list
                traveled[traveledIndex] = gridX + gridY * COLUMNS;
                traveledIndex = (traveledIndex + 1) % HISTORY;
            }
        }
    }

    void walk()
    {
        if (state == "walk")
        {
            x += dirX[dir] / cast(float)(dirD[dir]);
            y += dirY[dir] / cast(float)(dirD[dir]);

            // reached new tile
            step -= 1;
            if (step == 0)
            {
                x = gridX;
                y = gridY;
                state = "idle";
            }
        }
    }

    void getMoveCommand()
    {
        command = "move";
        traveled[] = -1;
    }
}

// directions
static immutable int[8] dirX = [ 0,  1,  1,  1,  0, -1, -1, -1];
static immutable int[8] dirY = [ 1,  1,  0, -1, -1, -1,  0,  1];
static immutable int[8] dirD = [10, 14, 10, 14, 10, 14, 10, 14];


class Grid
{
    Unit[] units;

    int[ROWS*COLUMNS] block;
    void setBlock(int x, int y, int b)  {  block[x + y * COLUMNS] = b;    }
    int  getBlock(int x, int y)
    {
        if (x < 0 || y < 0 || x >= COLUMNS || y >= ROWS)
            return -1; // invalid
  
        return block[x + y * COLUMNS]; 
    }

    int[ROWS*COLUMNS] path;
    void setPath(int x, int y, int dist) {  path[x + y * COLUMNS] = dist; }
    int getPath(int x, int y)
    {
        if (x < 0 || y < 0 || x >= COLUMNS || y >= ROWS)
            return -1; // correct?

        return path[x + y * COLUMNS]; 
    }

    int destX;
    int destY;
    bool hasPath = false;

    float tileSize;
    float offsetX;
    float offsetY;

    this()
    {
        clearWorld();
    }

    void clearWorld()
    {
        destX = -1;
        destY = -1;
        units = [];
        // create original map
        for (int j = 0; j < ROWS; ++j)
        {
            for (int i = 0; i < COLUMNS; ++i)
            {
                int b = 0;
                if (i == 0 || j == 0 || i == (COLUMNS - 1) || j == (ROWS - 1))
                    b = 1;
                setBlock(i, j, b);
            }
        }
    }

    void update(Keyboard keyboard, Mouse mouse, float screenWidth, float screenHeight)
    {
        int mx = cast(int)( (mouse.x - offsetX) / tileSize);
        int my = cast(int)( (mouse.y - offsetY) / tileSize);

        // place a wall
        if (mouse.left && getBlock(mx, my) == 0)
        {
            setBlock(mx, my, 1);
            hasPath = false;
        }

        // removes a wall
        if (mouse.right && getBlock(mx, my) == 1)
        {            
            setBlock(mx, my, 0);
            hasPath = false;
        }

        // place destination
        if (keyboard.isPressed("d") && getBlock(mx, my) != 1  && getBlock(mx, my) != -1)
        {
            destX = mx;
            destY = my;
            findPath();
            foreach(unit; units)
                unit.getMoveCommand();
        }

        // create unit
        if (keyboard.isPressed("u") && getBlock(mx, my) == 0)
        {
            addUnit(mx, my);
        }
        foreach(unit; units)
            unit.update();
    }

    void addUnit(int x, int y)
    {
        units ~= new Unit(this, x, y);
    }

    void draw(Canvas* canvas)
    {
        drawWalls(canvas);
        drawDestination(canvas);
        foreach(unit; units)
            unit.draw(canvas);
    }

    void drawWalls(Canvas* canvas)
    {
        for (int j = 0; j < ROWS; ++j)
        {
            for (int i = 0; i < COLUMNS; ++i)
            {
                int tile =  getBlock(i, j);
                canvas.fillStyle = (tile == 1) ? "#ff2d8a" : "#fff";
                canvas.fillRect(offsetX + i * tileSize, offsetY + j * tileSize, tileSize, tileSize);
            }
        }
    }

    void drawDestination(Canvas* canvas)
    {
        if (destX > -1)
        {
            canvas.fillStyle = "#5aff93";
            canvas.fillRect(offsetX + destX * tileSize, offsetY + destY * tileSize, tileSize, tileSize);
        }
    }

    struct PathPart
    {
        int x;
        int y;
        int dist;
    }

    PathPart[] node; // note: this buffer reused, for GC pressure reason
    int nodeStart;   // min-index
    int nodeIndex;   // max-index, current length is nodeIndex - nodeStart

    void clearNodeList()
    {
        nodeStart = 0;
        nodeIndex = 0;
    }

    void pushNode(PathPart n)
    {
        if (nodeIndex + 1 >= node.length)
            node.length = node.length * 3 + 1;
        node[nodeIndex++] = n;
    }

    void findPath()
    {
        // This is basically Dijkstra's algorithm, 
        // whose result is used for every unit.
        path[] = -1;

        clearNodeList();
        pushNode(PathPart(destX, destY, 0));
        setPath(destX, destY, 0);

        // grow path
        while (nodeIndex - nodeStart > 0)
        {
            const(PathPart) current = node[nodeStart];

            // check all neighbours
            for (int i = 0; i < 8; ++i)
            {                  
                int nx = current.x + dirX[i];
                int ny = current.y + dirY[i];

                // stay in grid
                if (nx < 0 || ny < 0 || nx >= COLUMNS || ny >= ROWS)
                    continue;

                // skip block
                if (getBlock(nx, ny) == 1)
                    continue;

                // check if shorter distance
                if ( (current.dist + dirD[i] < getPath(nx, ny)) || (getPath(nx, ny) == -1) )
                {
                    setPath(nx, ny, current.dist + dirD[i] );
                    pushNode(PathPart(nx, ny, current.dist + dirD[i]));
                }
            }
            nodeStart++;
        }
        hasPath = true;
    }
}