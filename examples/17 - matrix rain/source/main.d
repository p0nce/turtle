import turtle;
import textmode;
import std.random;

// Note: generated with Cursor, I had almost nothing to change

int main(string[] args)
{
    runGame(new MatrixRainExample());
    return 0;
}

class MatrixRainExample : TurtleGame
{
    int[] rainDrops;
    char[] symbols;

    override void load()
    {
        setBackgroundColor(color("#000000"));
        console.size(80, 25);
        console.palette(TM_paletteVintage);

        rainDrops = new int[80];
        symbols = new char[80];
        foreach (ref drop; rainDrops) drop = uniform(0, 25);
        foreach (ref sym; symbols) sym = cast(char)uniform(33, 127);
    }

    override void update(double dt)
    {
        console.update(dt);
        if (keyboard.isDown("escape")) exitGame();

        foreach (i, ref drop; rainDrops)
        {
            if (++drop > 25)
            {
                drop = 0;
                symbols[i] = cast(char)uniform(33, 127);
            }
        }
    }

    override void draw()
    {
        ImageRef!RGBA fb = framebuffer();

        with (console)
        {
            cls();

            foreach (x, drop; rainDrops)
            {
                for (int y = 0; y < 25; y++)
                {
                    locate(cast(int)x, y);
                    if (y == drop)
                    {
                        fg(TM_colorWhite);
                        style(TM_styleShiny);
                        print(symbols[x]);
                    }
                    else if (y < drop && y >= drop - 5)
                    {
                        fg(TM_colorGreen);
                        int intensity = 15 - (drop - y) * 3;
                        style(TM_styleNone);
                        if (intensity > 10) style(TM_styleShiny);
                        print(cast(char)uniform(33, 127));
                    }
                }
            }

            outbuf(fb.pixels, fb.w, fb.h, fb.pitch);
            render();
        }
    }
}

