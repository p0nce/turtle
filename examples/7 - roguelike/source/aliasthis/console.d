module aliasthis.console;

import std.typecons,
       std.path,
       std.string,
       std.file;


import turtle;
import dplug.core;

public import aliasthis.chartable,
              aliasthis.utils;

struct Glyph
{
    ubyte fontIndex;
    RGBA foregroundColor;
    RGB backgroundColor;
}

enum 
{
    BG_OP_SET = 0,
    BG_OP_KEEP = 1
}

enum DEFORM_GLYPHS_TO_FIT = true;

class Console
{
    public
    {
        this(int width, int height)
        {
            _font = null;

            _width = width;
            _height = height;

            _glyphs.length = _width * _height;
        }

        ~this()
        {
        }

        @property width()
        {
            return _width;
        }

        @property height()
        {
            return _height;
        }

        void updateFont(int windowWidth, int windowHeight)
        {
            selectBestFontForDimension(windowWidth, windowHeight, _width, _height);
        }

        ref Glyph glyph(int x, int y)
        {
            return _glyphs[x + y * _width];
        }

        void setForegroundColor(RGB fg)
        {
            ubyte alpha = 255;
            setForegroundColor(RGBA(fg.r, fg.g, fg.b, alpha));
        }

        void setForegroundColor(RGBA fg)
        {
            _foregroundColor = fg;
        }

        void setBackgroundColor(RGBA bg)
        {
            _backgroundColor = bg;
        }

        void clear()
        {
            foreach (ref g ; _glyphs)
            {
                g.fontIndex = 0;
                g.foregroundColor = _foregroundColor;
                g.backgroundColor = RGB(_backgroundColor.r, _backgroundColor.g, _backgroundColor.b);
            }
        }

        void putChar(int cx, int cy, int fontIndex)
        {
            if (cx < 0 || cx >= _width || cy < 0 || cy >= _height)
                return;

            Glyph* g = &glyph(cx, cy);

            g.fontIndex = cast(ubyte)fontIndex;
            g.foregroundColor = _foregroundColor; // do not consider alpha, will be composited at render time

            if (_backgroundColor.a != 0)
            {
                RGB ba = RGB(_backgroundColor.r, _backgroundColor.g, _backgroundColor.b);
                g.backgroundColor = lerpColor(g.backgroundColor, ba, _backgroundColor.a / 255.0f);     
            }
        }

        void putText(int cx, int cy, string text)
        {
            int i = 0;
            foreach (dchar ch; text)
            {
                putChar(cx + i, cy, character(ch));
                i += 1;
            }
        }

        // format text into a rectangle
        void putFormattedText(int cx, int cy, int width, int height, string text)
        {
            int x = 0;
            int y = 0;
            dchar[] fifo;

            void flush()
            {
                foreach (dchar ch; fifo)
                {
                    if (ch != '\n')
                    {
                        // crop
                        if (cx < width && cy < height)
                            putChar(cx + x, cy + y, character(ch)); // draw char
                        x++;
                    }
                }
                fifo.length = 0;
            }

            foreach (size_t i, dchar ch; text)
            {
                if (ch == ' ')
                {
                    if (x + fifo.length < width)
                    {
                        flush();
                        fifo ~= ch;
                    }
                    else
                    {
                        x = 0;
                        y += 1;
                        if (fifo.length > 0 && fifo[0] == ' ')
                            fifo = fifo[1..$];
                        flush();
                        fifo ~= ch;
                    }
                }
                else if (ch == '\n')
                {
                    if (x + fifo.length < width)
                        flush();
                    x = 0;
                    y += 1;
                    flush();
                }
                else
                {
                    fifo ~= ch;
                }
            }
            flush();
        }

        void putImage(int cx, int cy, OwnedImage!RGBA surface, void delegate(int x, int y, out int charIndex, out RGBA fgColor) getCharStyle)
        {
            int w = surface.w;
            int h = surface.h;

            for(int y = 0; y < h; ++y)
            {
                RGBA[] scan = surface.scanline(y);

                for(int x = 0; x < w; ++x)
                {
                    RGBA color = scan[x];
                    Glyph* g = &glyph(x + cx, y + cy);

                    int charIndex;
                    RGBA fg;
                    getCharStyle(x, y, charIndex, fg);
                    g.backgroundColor = RGB(color.r, color.g, color.b);
                    g.foregroundColor = fg;
                    g.fontIndex = cast(ubyte)charIndex;
                }
            }
        }

        // Draw things, takes both the raw framebuffer and a Canvas.
        void flush(ImageRef!RGBA framebuffer, Canvas* canvas)
        {   
            // draw things
            framebuffer.fillAll(RGBA(0, 0, 0, 255));

            // draw characters background
            for (int j = 0; j < _height; ++j)
            {
                for (int i = 0; i < _width; ++i)
                {
                    Glyph g = glyph(i, j);
                    RGB bg = g.backgroundColor;

                    int k = i;
                    while (true)
                    {
                        if (k + 1 >= _width)
                            break;
                        Glyph gNext = glyph(k + 1, j);
                        if (bg != gNext.backgroundColor)
                            break;
                        k += 1;
                    }

                    int destX0 = _consoleOffsetX + i * _glyphWidth;
                    int destX1 = _consoleOffsetX + k * _glyphWidth;
                    int destY = _consoleOffsetY + j * _glyphHeight;
                    box2i destRect = box2i(destX0, destY, destX1 + _glyphWidth, destY + _glyphHeight);

                    i = k;
                    canvas.fillStyle = RGBA(g.backgroundColor.r, g.backgroundColor.g, g.backgroundColor.b, 255);
                    canvas.fillRect(destRect.min.x, destRect.min.y, destRect.width, destRect.height);
                }
            }

            int spacex = _glyphWidth - _fontWidth;
            int spacey = _glyphHeight - _fontHeight;
            assert(0 <= spacex && spacex <= 2);
            assert(0 <= spacey && spacey <= 2);

            // draw glyphs in foreground color

            for (int j = 0; j < _height; ++j)
            {
                for (int i = 0; i < _width; ++i)
                {
                    Glyph g = glyph(i, j);
                    int destX = _consoleOffsetX + i * _glyphWidth;
                    int destY = _consoleOffsetY + j * _glyphHeight;
                    if (spacex == 2) 
                        destX += 1;
                    if (spacey == 2) 
                        destY += 1;

                    box2i destRect = box2i(destX, destY, destX + _fontWidth, destY + _fontHeight);
                    
                    // optimization: skip index 0 (space)
                    if (g.fontIndex == 0)
                        continue;

                    RGBA fgGlyph = g.foregroundColor;
                    if (fgGlyph.a == 0)
                        continue;

                    box2i fontRect = glyphRect(g.fontIndex);

                    for (int y = 0; y < _fontHeight; ++y)
                    {
                        RGBA[] fontScanline = _font.scanline(y + fontRect.min.y);
                        RGBA[] outScan = framebuffer.scanline(destY + y);

                        for (int x = 0; x < _fontWidth; ++x)
                        {
                            RGBA fontColor = fontScanline[x + fontRect.min.x];
                            if (fontColor.a == 0)
                                continue;

                            // Modulate by glyph foregroundColor
                            fontColor.r = (fontColor.r * fgGlyph.r + 128) / 256;
                            fontColor.g = (fontColor.g * fgGlyph.g + 128) / 256;
                            fontColor.b = (fontColor.b * fgGlyph.b + 128) / 256;
                            fontColor.a = (fontColor.a * fgGlyph.a + 128) / 256;

                            outScan[destX + x] = blendColor(fontColor, outScan[destX], fontColor.a);
                        }
                    }
                }
            }
        }
    }

    private
    {        
        OwnedImage!RGBA _font;

        int _width;
        int _height;
        Glyph[] _glyphs;
        bool _isFullscreen;
        string _gameDir;

        // current colors
        RGBA _foregroundColor;
        RGBA _backgroundColor;

        int _fontWidth;
        int _fontHeight;

        int _glyphWidth;
        int _glyphHeight; // The glyph can be slightly larger than a font glyph

        int _consoleOffsetX;
        int _consoleOffsetY;

        box2i glyphRect(int fontIndex)
        {
            int ix = (fontIndex & 15);
            int iy = (fontIndex / 16);
            box2i rectFont = box2i(ix * _fontWidth, iy * _fontHeight, (ix + 1) * _fontWidth, (iy + 1) * _fontHeight);
            return rectFont;
        }

        void selectBestFontForDimension(int screenResX, int screenResY, int consoleWidth, int consoleHeight)
        {
            // find biggest font that can fit
            int[2][7] fontDim = 
            [
                [9, 14], [11, 17], [13, 20], [15, 24], [17, 27], [19, 30], [21, 33]
            ];

            int desktopWidth = screenResX;
            int desktopHeight = screenResY;

            int bestFont = 0;

            while (bestFont < 6
                   && fontDim[bestFont+1][0] * consoleWidth < desktopWidth 
                   && fontDim[bestFont+1][1] * consoleHeight < desktopHeight)
                bestFont++;

            _fontWidth = fontDim[bestFont][0];
            _fontHeight = fontDim[bestFont][1];

            // extend glyph size by up-to 2 pixels in each direction to better match the screen.
            _glyphWidth = _fontWidth;
            _glyphHeight = _fontHeight;

            if (DEFORM_GLYPHS_TO_FIT)
            {
                for (int s = 0; s < 2; ++s)
                {
                    if (consoleWidth * (_glyphWidth + 1) <= desktopWidth)
                        _glyphWidth++;
                    if (consoleHeight * (_glyphHeight + 1) <= desktopHeight)
                        _glyphHeight++;
                }
            }

            // initialize custom font
            
            string fontPath = format("data/fonts/consola_%sx%s.png", _fontWidth, _fontHeight);
            
            if (_font !is null)
                _font.destroyFree();

            ubyte[] data = cast(ubyte[]) std.file.read(fontPath);
            _font = loadOwnedImage(data);
            assert(_font.w == _fontWidth * 16);
            assert(_font.h == _fontHeight * 16);

            _consoleOffsetX = (desktopWidth - _glyphWidth * consoleWidth) / 2;
            _consoleOffsetY = (desktopHeight - _glyphHeight * consoleHeight) / 2;
        }
    }
}
