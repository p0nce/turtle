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

        RGBA8 bg8 = color("#eaf5ff").toRGBA8();
        RGBA bg = RGBA(bg8.r, bg8.g, bg8.b, bg8.a);

        int screenW = fb.w;
        int screenH = fb.h;
        int scaleX = screenW / (16 * tx);
        int scaleY = screenH / (16 * ty);
        int scale = scaleX < scaleY ? scaleX : scaleY;
        int marginX = (screenW - scale * 16 * tx)/2;
        int marginY = (screenH - scale * 16 * ty)/2;

        for (int j = 0; j < ty; j++) 
        {
            for (int i = 0; i < tx; i++) 
            {
                // tile to draw
                int newOne = _newArray[i+j*tx];

                int destX = marginX + i * 16 * scale;
                int destY = marginY + j * 16 * scale;

                if (newOne > EMPTY_TILE) 
                { 	                                        
                    int y = (newOne & 0x70); // select row base on team
                    int x = (newOne & 15) * 16;
                    drawImage(fb, playersimg, x , y, 16, 16, destX, destY, scale, bg);
                }                    
                else if (newOne < EMPTY_TILE) 
                {                        
                    int x = ((-newOne - 2) /* & 15*/ ) * 16;
                    drawImage(fb, othersimg, 0, x, 16, 16, destX, destY, scale, bg);
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
                int j = 16 * tplayer._dir;
                if (tplayer._invincibility > 0) 
                {
	             	continue;
                }
                else if (tplayer._warning > 0) 
                {
	                j += 64;
                }
                else if (tplayer._turbo)
                {
	             	j += 128;   
                }             

                if ((x >= 0) && (x < tx) && (y >= 0) && (y < ty))
                {
                    drawImage(fb, eyesimg, 0, j, 16, 16,  marginX + x * 16 * scale,  marginY + y * 16 * scale, scale);
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

// special case when background is known
void drawImage(ImageRef!RGBA fb, Image* image, 
               int srcX, int srcY, 
               int w, int h, 
               int destX, int destY, 
               int scale,
               RGBA bg)
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
            RGBA col = blendColor(fg, bg, fg.a);
            
            for (int sy = 0; sy < scale; ++sy)
            {
                RGBA[] dest = fb.scanline(destY + y * scale + sy);

                int xx = destX + x * scale;
                dest[xx..xx+scale] = col;
            }
        }
    }
}