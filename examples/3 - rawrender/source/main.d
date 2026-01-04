import turtle;

import dplug.core;
import dplug.graphics;

int main(string[] args)
{
    runGame(new RawRenderExample);
    return 0;
}

class RawRenderExample : TurtleGame
{
    override void load()
    {
        setBackgroundColor( color("black") );

        // Stick the text console to top-right
        TM_Options opt;
        opt.halign = TM_horzAlignRight;
        opt.valign = TM_vertAlignTop;
        console.options(opt);        
    }

    enum GRID_SUBSAMPLING = 2;

    override void resized(float width, float height)
    {
        grid.resize(cast(int)(1 + width / GRID_SUBSAMPLING), cast(int)(1 + height / GRID_SUBSAMPLING));

        grid.applyBrush(width / 2 / GRID_SUBSAMPLING, height / 2 / GRID_SUBSAMPLING, 30, CellType.sand);
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;
        grid.update(dt);
    }

    override void draw()
    {
        ImageRef!RGBA framebuf = framebuffer();
        int W = framebuf.w;
        int H = framebuf.h;

        for (int y = 0; y < H; ++y)
        {
            RGBA[] scan = framebuf.scanline(y);

            for (int x = 0; x < W; ++x)
            {
                scan[x] = grid[x/GRID_SUBSAMPLING, y/GRID_SUBSAMPLING].color();
            }
        }

        // draw buttons
        for(CellType type = CellType.sand; type <= CellType.max; ++type)
        {
            canvas.fillStyle = getCellTypeColor(type);
            canvas.fillRect(buttonBox(type));
            if (current == type)
            {
                canvas.fillStyle = RGBA(255, 0, 0, 128);
                Rect2 box = buttonBox(type);
                box.position += Vector2(4, 4);
                box.size -= Vector2(8, 8);
                canvas.fillRect(box);
            }
        }

        // Show console
        {
            console.cls;
            int x = console.columns() - 19;
            console.box(x, 0, 19, 7, TM_boxLargeH);
            console.locate(x+2, 2);
            final switch(current)
            {
                case CellType.sand: 
                    console.cprint("Selected: <yellow>sand</yellow>"); 
                    break;
                case CellType.water: 
                    console.cprint("Selected: <lblue>water</lblue>"); 
                    break;
                case CellType.empty: 
                    console.cprint("Selected: empty"); 
                    break;
            }
            console.locate(x+2, 4);
            console.cprint("<lcyan>LMB</lcyan>=Add <lcyan>RMB</lcyan>=Del");
        }
    }      

    override void mousePressed(float x, float y, MouseButton button, int repeat)
    {
        // pressed a button?
        for(CellType type = CellType.sand; type <= CellType.max; ++type)
        {
            if (buttonBox(type).has_point(Point2(x, y)))
            {
                current = type;
                _drag = false;
                return;
            }
        }

        float px = cast(float)x / GRID_SUBSAMPLING;
        float py = cast(float)y / GRID_SUBSAMPLING;

        if (button == MouseButton.right)
        {
            _drag = true; // TODO: add a Mouse.startDragging() API
            grid.applyBrush(px, py, brushSize, CellType.empty);
        }
        else
        {
            _drag = true;
            grid.applyBrush(px, py, brushSize, current);
        }
    }

    override void mouseMoved(float x, float y, float dx, float dy)
    {
        if (!_drag)
            return;
        float px = cast(float)x / GRID_SUBSAMPLING;
        float py = cast(float)y / GRID_SUBSAMPLING;
        if (mouse.isPressed(MouseButton.right))
            grid.applyBrush(px, py, brushSize, CellType.empty);
        if (mouse.isPressed(MouseButton.left))
            grid.applyBrush(px, py, brushSize, current);
    }

    override void mouseWheel(float wheelX, float wheelY)
    {
        brushSize = brushSize * (1.2 ^^ wheelY);
        if (brushSize < 1) brushSize = 1;
        if (brushSize > 100) brushSize = 100;
    }

    // Current brush size (change with mouse wheel)
    float brushSize = 30.0f;

    // Grid date
    Grid grid;

    // Selected cell type
    CellType current = CellType.sand;

    Rect2 buttonBox(CellType type)
    {
        return Rect2(8, 8 + 40 * (cast(int)type - 1), 24, 24);
    }    

    bool _drag = false;
}


enum CellType : ubyte
{
    empty,
    sand,
    water
}

RGBA getCellTypeColor(CellType type)
{
    final switch (type) with (CellType)
    {
        case empty: return RGBA(0, 0, 0, 255);
        case sand: return RGBA(227, 208, 119, 255);
        case water: return RGBA(0, 122, 204, 255);
    }
}

struct Cell
{
    CellType type = CellType.empty;

    RGBA color()
    {
        return getCellTypeColor(type);
    }

    // Re-type a cell
    void createCell(CellType newType)
    {
        type = newType;
    }

    bool isEmpty()
    {
        return type == CellType.empty;
    }

    void moveTo(Cell* target)
    {
        assert(target.type == CellType.empty);
        target.type = type;
        type = CellType.empty;        
    }
}

struct Grid
{
    Cell[] cells;
    uint steps; // simulation steps since the beginning.

    void resize(int width, int height)
    {    
        this.width = width;
        this.height = height;
        cells.length = width * height;
        cells[] = Cell.init;
    }

    bool contains(size_t x, size_t y)
    {
        return (x < width) && (y < height);
    }

    ref Cell opIndex(size_t x, size_t y)
    {
        assert(contains(x, y));
        return cells[x + y * width];
    }
    ref Cell cell(size_t x, size_t y)
    {
        return this[x, y];
    }

    void applyBrush(float cx, float cy, float brushSize, CellType type)
    {
        float brushSizePow2 = brushSize * brushSize;
        for (int y = 0; y < height; ++y)
        {
            for (int x = 0; x < width; ++x)
            {
                float dx = x - cx;
                float dy = y - cy;
                if (dx*dx+dy*dy < brushSizePow2)
                {
                    cells[x + y * width].createCell(type);
                }
            }
        }
    }

    void update(double dt)
    {
        enum SIMULATION_STEPS_PER_FRAME = 6;
        for (int N = 0; N < SIMULATION_STEPS_PER_FRAME; ++N)
        {
            for (int y = height - 1; y >= 0; --y)
            {
                // Should this whole row be left to right, or right to left?
                bool l2r = randomDecision(steps, N, 0);

                int xstart = l2r ? 0 : width - 1;
                int xend = l2r ? width : -1;
                int xincr = l2r ? 1 : -1;
                for (int x = xstart; x != xend; x += xincr)
                {
                    Cell* t = &cells[x + y * width];
                    final switch (t.type) with (CellType)
                    {
                        case empty: 
                            break;
                        case sand: 
                            updateSand(t, x, y);
                            break;
                        case water: 
                            updateWater(t, x, y);
                            break;
                    }
                }
            }
            steps++;
        }
    }    

private:
    int width, height;

    void updateSand(Cell* t, size_t x, size_t y)
    {
        if (contains(x, y+1))
        {
            Cell* below = &cell(x, y + 1);
            if (below.isEmpty)
            {
                t.moveTo(below); // fall
                return;
            }

            bool bottomLeft = false, 
                 bottomRight = false;
            Cell* rbelow, lbelow;

            if (contains(x+1, y+1))
            {
                rbelow = &cell(x + 1, y + 1);
                if (rbelow.isEmpty)
                {
                    bottomRight = true;
                }
            }

            if (contains(x-1, y+1))
            {
                lbelow = &cell(x - 1, y + 1);
                if (lbelow.isEmpty)
                {
                    bottomLeft = true;
                }
            }

            if (bottomLeft && bottomRight)
            {
                // decide one time right, one time left alternatively
                if (randomDecision(steps, x, y))
                    t.moveTo(lbelow);
                else
                    t.moveTo(rbelow);
                return;
            }
            else if (bottomLeft)
            {
                t.moveTo(lbelow);
                return;
            }
            else if (bottomRight)
            {
                t.moveTo(rbelow);
                return;
            }
        }
    }

    bool randomDecision(uint step, size_t x, size_t y)
    {
        // compute seed to decorrelate x, y, and step 
        uint seed = cast(uint)x * 389 + cast(uint)y * 196613 + step * 50331653;
        return ((seed >> 5) & 1) != 0;
    }

    void updateWater(Cell* t, size_t x, size_t y)
    {
        // water is like sand but with other possibilities for movement
        updateSand(t, x, y);

        if (t.isEmpty) 
            return;

        bool left = false, 
             right = false;
        Cell* cellRight, cellLeft;

        if (contains(x+1, y+0))
        {
            cellRight = &cell(x + 1, y + 0);
            if (cellRight.isEmpty)
            {
                right = true;
            }
        }

        if (contains(x-1, y+0))
        {
            cellLeft = &cell(x - 1, y + 0);
            if (cellLeft.isEmpty)
            {
                left = true;
            }
        }

        if (left && right)
        {
            // decide one time right, one time left alternatively
            if (randomDecision(steps, x, y))
                t.moveTo(cellLeft);
            else
                t.moveTo(cellRight);
            return;
        }
        else if (left)
        {
            t.moveTo(cellLeft);
            return;
        }
        else if (right)
        {
            t.moveTo(cellRight);
            return;
        }
    }
}