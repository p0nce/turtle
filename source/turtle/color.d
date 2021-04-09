module turtle.color;


alias Color = RGBA;

import dplug.canvas.htmlcolors;


Color color(int r, int g, int b, int a)
{
    if (r < 0) r = 0;
    if (g < 0) g = 0;
    if (b < 0) b = 0;
    if (a < 0) a = 0;
    if (r > 255) r = 255;
    if (g > 255) g = 255;
    if (b > 255) b = 255;
    if (a > 255) a = 255;

    RGBA res;
    res.r = cast(ubyte)r;
    res.g = cast(ubyte)g;
    res.b = cast(ubyte)b;
    res.a = cast(ubyte)a;
    return res;
}

Color color(const(char)[] htmlColorString)
{
    string error;
    RGBA res;
    if (parseHTMLColor(htmlColorString, res, error))
    {
        return res;
    }
    else
        throw new Exception(error);
}