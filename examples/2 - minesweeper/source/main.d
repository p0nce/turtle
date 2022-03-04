import turtle;
static import std.random;

import dosfont;

int main(string[] args)
{
    runGame(new MinesweeperExample);
    return 0;
}

class MinesweeperExample : TurtleGame
{
    enum GX = 21;
    enum GY = 12;
    enum MINE_DENSITY = 17.0f;

    override void load()
    {
        setBackgroundColor( RGBA(0, 11, 28, 255) );
        makeNewGrid();
    }

    override void update(double dt)
    {     
        if (keyboard.isDown("return")) makeNewGrid;
        if (keyboard.isDown("escape")) exitGame;
        if (winCondition) gameWin = true;
    }

    override void resized(float width, float height)
    {
        _WX = windowWidth();
        _WY = windowHeight();
        double SX = cast(int)(_WX / (GX + 2));
        double SY = cast(int)(_WY / (GY + 2));
        _S = SX < SY ? SX : SY;
        _marginX = (_WX - _S*GX)/2;
        _marginY = (_WY - _S*GY)/2;
    }

    // Note: this use both the canvas and direct frame buffer access (for text)
    override void draw()
    {
        ImageRef!RGBA fb = framebuffer();

        if (gameWin)
        {
            drawDOSText(fb, DOSFontType.small8x8, 
                        "WIN! Press ENTER to start a new game", 
                        (elapsedTime() % 0.5f < 0.25f) ? NUMBERS_COLORS[1] : RGBA(0, 0, 0, 0),
                        cast(int)(_S / 2), cast(int)(_S / 2), 0, _S / 16);
        }
        if (gameOver)
        {
            drawDOSText(fb, DOSFontType.small8x8, 
                        "FAIL! Press ENTER to start a new game", 
                        (elapsedTime() % 0.5f < 0.25f) ? NUMBERS_COLORS[7] : RGBA(0, 0, 0, 0),
                        cast(int)(_S / 2), cast(int)(_S / 2), 0, _S / 16);
        }

        with(canvas)
        {
            save();

            translate(_marginX , _marginY);
            scale(_S, _S);

            fillStyle = color(255, 0, 0, 255);

            for (int y = 0; y < GY; ++y)
            {
                for (int x = 0; x < GX; ++x)
                {
                    char ch = displayState(x, y);
                    save();
                    double margin = 0.05;
                    translate(x + margin, y + margin);
                    scale(1.0 - margin*2);
                    int shown = isShown[y][x];
                    if (shown == HIDDEN || shown == FLAG)
                    {
                        fillStyle = RGBA(60, 161, 247, 255);
                        fillRect(0, 0, 1, 1);

                        fillStyle = RGBA(55, 110, 178, 255);
                        fillRect(0, 0.9, 1, 0.1);
                        fillRect(0.9, 0, 0.1, 1);

                        fillStyle = RGBA(74, 146, 237, 255);                        
                        fillRect(0, 0, 1, 0.1);
                        fillRect(0, 0, 0.1, 1);

                        if (shown == FLAG)
                        {
                            fillStyle = RGBA(0, 11, 28, 255);
                            fillRect(0.3, 0.25, 0.3, 0.25);

                            fillStyle = RGBA(55, 110, 178, 255);
                            fillRect(0.6, 0.25, 0.1, 0.5);
                        }
                    }
                    else
                    {                        
                        if (ch != '0')
                        {
                            float textScale = _S / 16;
                            int textX = cast(int)(0.5 + _marginX + x * _S + 4 * textScale);
                            int textY = cast(int)(0.5 + _marginY + y * _S + 4 * textScale);

                            RGBA textColor;
                            if (ch == '*')
                                textColor = color("#9d4e24");
                            else
                            {
                                textColor = NUMBERS_COLORS[ch - '0'];
                            }
                            drawDOSText(fb, DOSFontType.small8x8, (&ch)[0..1], textColor,
                                        textX, textY, 0, textScale);
                        }
                    }
                    if (x == _sx && y == _sy && isClickable(x, y))
                    {
                        fillStyle = "#ffff0020";
                        fillRect(0, 0, 1, 1);
                    }
                    restore;
                }
            }
        }                
    }

    bool isClickable(int x, int y)
    {
        if (gameWin || gameOver) return false;
        if (isShown[y][x] != SHOWN) return true;
        int mines = neighbourMines(x, y);
        if (mines == 0) return false;
        int flags = neighbourFlags(x, y);
        if (mines == flags)
        {
            int hidden = neighbourHidden(x, y);
            return hidden > 0;
        }
        else
            return false;
    }

    override void mouseMoved(float x, float y, float dx, float dy)
    {
        setSelection(x, y);
    }

    override void mouseReleased(float x, float y, MouseButton button)
    {
        if (gameWin || gameOver)
            return;
        setSelection(x, y);
        if (_sx != -1)
        {
            if (button == MouseButton.right)
            {
                if (isShown[_sy][_sx] == HIDDEN) 
                    isShown[_sy][_sx] = FLAG;
                else if (isShown[_sy][_sx] == FLAG) 
                    isShown[_sy][_sx] = HIDDEN;
            }
            else if (isShown[_sy][_sx] == FLAG)
            {
                isShown[_sy][_sx] = HIDDEN;
            }
            else if (isShown[_sy][_sx] == HIDDEN)
            {
                reveal(_sx, _sy);
            }
            else
            {
                int mines = neighbourMines(_sx, _sy);
                if (mines > 0)
                {                    
                    int flags = neighbourFlags(_sx, _sy);
                    if (flags == mines)
                        for (int dy = -1; dy < 2; ++dy)
                            for (int dx = -1; dx < 2; ++dx)
                                if (isInGrid(_sx + dx, _sy + dy))
                                    if (isShown[_sy+dy][_sx+dx] == HIDDEN)
                                        reveal(_sx + dx, _sy + dy);
                }
            }
        }
    }

private:
    bool[GX][GY] isMine;

    bool gameOver;
    bool gameWin;
    int HIDDEN = 0;
    int FLAG = 1;
    int SHOWN = 2;
    int[GX][GY] isShown;

    static immutable RGBA[9] NUMBERS_COLORS = 
    [
        RGBA (42,  76, 129, 255), // '1'
        RGBA(128, 219, 161, 255),
        RGBA(179, 103,  31, 255),
        RGBA(231, 207,  97, 255), 
        RGBA(  0, 170, 170, 255),
        RGBA(255,  97, 227, 255), 
        RGBA(198, 202, 255, 255),
        RGBA(222, 28, 80, 255),   // '8'
        RGBA(255, 255, 255, 255),
    ];

    int _sx = -1, _sy = -1;
    float _WX, _WY, _S, _marginX, _marginY;

    bool isInGrid(int x, int y)
    {
        return x >= 0 && y >= 0 && x < GX && y < GY;
    }

    void makeNewGrid()
    {
        gameWin = false;
        gameOver = false;
        for (int y = 0; y < GY; ++y)
        {
            for (int x = 0; x < GX; ++x)
            {
                isShown[y][x] = HIDDEN;
                isMine[y][x] = std.random.uniform(0, 100) < MINE_DENSITY;
            }
        }
    }

    bool winCondition()
    {
        for (int y = 0; y < GY; ++y)
            for (int x = 0; x < GX; ++x)
            {
                if (isMine[y][x] && (isShown[y][x] != FLAG)) 
                    return false;
                if (!isMine[y][x] && (isShown[y][x] == FLAG)) 
                    return false;
            }
        return true;
    }

    void setSelection(float mouseX, float mouseY)
    {
        _sx = cast(int)( (mouseX - _marginX) / _S);
        _sy = cast(int)( (mouseY - _marginY) / _S);
        if (!isInGrid(_sx, _sy))
            _sx = _sy = 1;
    }

    char displayState(int x, int y)
    {
        if (!isShown[y][x])
            return '?';

        if (isMine[y][x])
            return '*';

        return cast(char)('0' + neighbourMines(x, y));
    }

    int neighbourMines(int x, int y)
    {
        int mines = 0;
        for (int dy = -1; dy < 2; ++dy)
            for (int dx = -1; dx < 2; ++dx)
                if (isInGrid(x+dx, y+dy))
                    if (isMine[y+dy][x+dx])
                        mines += 1;
        return mines;
    }

    int neighbourThatAre(int x, int y, int which)
    {
        int flags = 0;
        for (int dy = -1; dy < 2; ++dy)
            for (int dx = -1; dx < 2; ++dx)
                if (isInGrid(x+dx, y+dy))
                    if (isShown[y+dy][x+dx] == which)
                        flags += 1;
        return flags;
    }

    int neighbourFlags(int x, int y)
    {
        return neighbourThatAre(x, y, FLAG);
    }

    int neighbourHidden(int x, int y)
    {
        return neighbourThatAre(x, y, HIDDEN);
    }

    void reveal(int x, int y)
    {
        if (isShown[y][x] != HIDDEN)
            return;

        isShown[y][x] = SHOWN;
        char ch = displayState(x, y);

        if (ch == '*')
            gameOver = true;

        // recurse if free space
        if (ch == '0')
        {
            for (int dy = -1; dy < 2; ++dy)
            {
                for (int dx = -1; dx < 2; ++dx)
                {
                    if (isInGrid(x+dx, y+dy))
                        reveal(x+dx, y+dy);
                }
            }
        }
    }
}

