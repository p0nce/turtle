module viewport;

import std.stdio;
import dplug.core.vec;
import dplug.graphics;
import gamut;
import constants;
import bullet;
import game;
import texture;
import player;
import world;
import colors;




// Stateful thing whose task is to display the surroundings of a player
// It owns a Camera to that purpose.
// originally used complex caching to avoid HTML5 Canvas redraw
class Viewport
{
    int _width, _height;
    Player _player;

    Vec!int _array;
    Vec!int _newArray;
    Vec!int _scratch;

    this(SnakeGame game, Player player, int w, int h)
    {
        _width = w;
        _height = h;
        _game = game;
        _world = game.world;
        _camera = Camera(game, 0, 0);
        _textures = game._textures;
        _player = player;

        int mW = _width;
        int mH = _height;

        _playersTexture = _textures.get(TEXTURE_PLAYERS);
        _otherTexture   = _textures.get(TEXTURE_OTHERTILES);
        _eyesTexture    = _textures.get(TEXTURE_EYES);

        _array.resize(mH * mW);
        _newArray.resize(mH * mW);
        _scratch.resize((mH + 2) * (mW + 2));
        moveCamera();
    }

    void moveCamera()
    {
        _camera.follow(_player, -(_width >> 1), -(_height >> 1));
    }

    SnakeGame _game;
    World* _world;
    Camera _camera;
    TextureManager _textures;
    Image* _playersTexture;
    Image* _otherTexture;
    Image* _eyesTexture;

    void render(ImageRef!RGBA fb)
    {
        alias camera = _camera;
        alias textures = _textures;
        alias world = _world;
        alias player = _player;

        size_t nPlayers =_game.players.length;

        int camx = camera._x;
        int camy = camera._y;
        alias playersimg = _playersTexture;
        alias othersimg = _otherTexture;
        alias eyesimg = _eyesTexture;

        int tx = _width;
        int ty = _height;

        // get tiles to display
        world.getTiles(camx, camy, tx, ty, _newArray, _scratch);

        RGBA8 bg8 = color(/*"#eaf5ff"*/"#ffffff").toRGBA8();
        RGBA bg = RGBA(bg8.r, bg8.g, bg8.b, bg8.a);

        int screenW = fb.w;
        int screenH = fb.h;
        int scaleX = screenW / (TILE_WIDTH_IN_PIXELS * tx);
        int scaleY = screenH / (TILE_HEIGHT_IN_PIXELS * ty);
        int scale = scaleX < scaleY ? scaleX : scaleY;
        int marginX = (screenW - scale * TILE_WIDTH_IN_PIXELS * tx)/2;
        int marginY = (screenH - scale * TILE_HEIGHT_IN_PIXELS * ty)/2;

        for (int j = 0; j < ty; j++) 
        {
            for (int i = 0; i < tx; i++) 
            {
                // tile to draw
                int newOne = _newArray[i+j*tx];
                int destX = marginX + i * TILE_WIDTH_IN_PIXELS * scale;
                int destY = marginY + j * TILE_HEIGHT_IN_PIXELS * scale;

                if (newOne > EMPTY_TILE) 
                {
                    // There is only 8 teams for now
                    int team = (newOne & 0x70) >> 4;
                    int y = team * TILE_HEIGHT_IN_PIXELS; // select row base on team
                    int x = (newOne & 15) * TILE_WIDTH_IN_PIXELS;
                    drawImageCopy(fb, playersimg, x , y, TILE_WIDTH_IN_PIXELS, TILE_HEIGHT_IN_PIXELS, destX, destY, scale);
                }
                else if (newOne < EMPTY_TILE) 
                {
                    int y = ((-newOne - 2) /* & 15*/ ) * TILE_HEIGHT_IN_PIXELS;
                    drawImageCopy(fb, 
                                  othersimg, 
                                  0, 
                                  y, 
                                  TILE_WIDTH_IN_PIXELS, 
                                  TILE_HEIGHT_IN_PIXELS, destX, destY, scale);
                }
                else
                {
                    // empty tile
                }
            }
        }

        for (int i = 0; i < nPlayers; ++i)
        {
			/* draw eyes of players that are visible */
			Player tplayer = _game.players[i];
            if (tplayer._state == STATE_ALIVE)
            {
                int x = (tplayer._posx - camx) & world._widthMask;
                int y = (tplayer._posy - camy) & world._heightMask;
                int j = TILE_WIDTH_IN_PIXELS * tplayer._dir;
                if (tplayer._invincibility > 0)
                {
	                continue;
                }
                else if (tplayer._warning > 0)
                {
	                j += TILE_HEIGHT_IN_PIXELS*4;
                }
                else if (tplayer._turbo)
                {
	                j += TILE_HEIGHT_IN_PIXELS*8;
                }

                int destX = marginX + x * TILE_WIDTH_IN_PIXELS * scale;
                int destY = marginY + y * TILE_HEIGHT_IN_PIXELS * scale;

                if ((x >= 0) && (x < tx) && (y >= 0) && (y < ty))
                {
                    drawImage(fb, eyesimg, 0, j, TILE_WIDTH_IN_PIXELS, TILE_HEIGHT_IN_PIXELS, destX, destY, scale);
                }
            }
        }
    }
}

// composite image on background image
void drawImage(ImageRef!RGBA fb, Image* image, 
               int srcX, int srcY, 
               int w, int h, 
               int destX, int destY, 
               int scale)
{
    assert(fb.w >= destX + w * scale);
    assert(fb.h >= destY + h * scale);

    for (int y = 0; y < h; ++y)
    {
        RGBA[] scan = cast(RGBA[]) image.scanline(srcY + y);

        for (int x = 0; x < w; ++x)
        {
            RGBA fg = scan[srcX + x];
            if (fg.a == 0) continue;

            for (int sy = 0; sy < scale; ++sy)
            {
                RGBA[] dest = fb.scanline(destY + y * scale + sy);

                // PERF: except for the eyes, we already know value of the bg
                for (int sx = 0; sx < scale; ++sx)
                {
                    int xx = destX + x * scale + sx;
                    RGBA bg = dest[xx];
                    RGBA col = blendColor(fg, bg, fg.a);
                    dest[xx] = col;
                }
            }
        }
    }
}

// No blend version
void drawImageCopy(ImageRef!RGBA fb, Image* image, 
               int srcX, int srcY, 
               int w, int h, 
               int destX, int destY, 
               int scale)
{
    assert(fb.w >= destX + w * scale);
    assert(fb.h >= destY + h * scale);
    static assert(int.sizeof == RGBA.sizeof);

    for (int y = 0; y < h; ++y)
    {
        int[] scan = cast(int[]) image.scanline(srcY + y);
        for (int x = 0; x < w; ++x)
        {
            int fg = scan.ptr[srcX + x];
            if ((fg >>> 24) == 0) continue;

            for (int sy = 0; sy < scale; ++sy)
            {
                int* dest = cast(int*)(fb.scanline(destY + y * scale + sy).ptr);
                int xx = destX + x * scale;
                dest[xx..xx+scale] = fg;
            }
        }
    }
}