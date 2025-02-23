module world;

import dplug.core.vec;
import constants;

enum 
    SLOT_UP = 1,
    SLOT_DOWN = 2,
    SLOT_LEFT = 4,
    SLOT_RIGHT = 8,
    EMPTY_TILE = -1,
    WORLD_EMPTY = 0,
    WORLD_FIREY = -1,
    WORLD_FIRER = -2,
    WORLD_DEBRIS = -3,
    WORLD_BULLET_UP = -4,
    WORLD_BULLET_DOWN = -5,
    WORLD_BULLET_LEFT = -6,
    WORLD_BULLET_RIGHT = -7,
    WORLD_WALL_BLUE = -8,
    WORLD_WALL_GREEN = -9,
    WORLD_WALL_ORANGE = -10,
    WORLD_WALL_YELLOW = -11,
    WORLD_WALL_WHITE = -12,
    WORLD_WALL_BLACK = -13,
    WORLD_WALL_RED = -14,
    WORLD_WALL_PINK = -15,
    WORLD_WALL_VIOLET = -16,
    WORLD_WALL_GREY = -17,
    WORLD_WALL_CYAN = -18,
    WORLD_POWERUP_YELLOW = -19,
    WORLD_POWERUP_GREEN = -20,
    WORLD_POWERUP_PINK = -21,
    WORLD_POWERUP_ORANGE = -22,
    WORLD_TRIANGLE_SW = -23,
    WORLD_TRIANGLE_NW = -24,
    WORLD_TRIANGLE_NE = -25,
    WORLD_TRIANGLE_SE = -26;

// the world contains occupation data
// 0: empty place
// 1-16: player of the team 1-16
// < 0: other tile

// it can return tiles
// >= 0 player stuff
// -1: empty
// -n: other tiles

struct World
{
    int _width_shift;
    int _height_shift;
    int _width;
    int _widthMask;
    int _height;
    int _heightMask;
    Vec!int _array;

    int width(){return _width;}
    int height(){return _height;}

    this(int w_log_2, int h_log_2)
    {
        this._width_shift = w_log_2;
        this._height_shift = h_log_2;
        
        int w = (1 << w_log_2), h = (1 << h_log_2);
        this._width = w;
        this._widthMask = (w - 1);
        this._height = h;
        this._heightMask = (h - 1);
        
        int len = w * h;
        this._array.resize(len);
        
        int i = 0, j = 0;
        for (i = 0; i < len; ++i)
    	{
    		this._array[i] = WORLD_EMPTY;
        }    
        
        int wallWidth = 1;
        switch(min_int(w_log_2, h_log_2))
        {
            case 6:
                wallWidth = 1;
                break;          
            case 7:
                wallWidth = 2;
                break;
            case 8:
                wallWidth = 8;
                break;
            case 9:
                wallWidth = 16;
                break;
            default:
                assert(0);
        }
        
        for (j = 0; j < wallWidth; ++j) 
        {
            for (i = 0; i < w; ++i) 
            {
                set(i, j, WORLD_WALL_BLUE);
                set(i, h - 1 - j, WORLD_WALL_BLUE);
            }           
        }
        
        for (i = 0; i < wallWidth; ++i) 
        {
            for (j = 0; j < h; ++j) 
            {
                set(i, j, WORLD_WALL_BLUE);
                set(w - 1 - i, j, WORLD_WALL_BLUE);
            }        
        }        
    }

    void set(int i, int j, int e)
    {
        this._array[j * this._width + i ] = e;
    }
    
    void setSecure(int i, int j, int e)
    {
        this._array[ (j & this._heightMask) * this._width + (i & this._widthMask) ] = e;
    }
    
    int get(int i, int j)
    {
        return this._array[((j & this._heightMask) * this._width) + (i & this._widthMask)]; //wrap around
    }
    
    void getLine(int i, int j, int count, ref Vec!int buffer, int index)
    {
        int ii = (i & this._widthMask);
        int jj = (j & this._heightMask);
        int w = this._width;
        int sindex = jj * w + ii;
        
        for (int k = 0; k < count; ++k) 
        {
            //var rx = ii + k;
            if ((ii + k) == w) 
            {
                sindex -= w;
            }
            buffer[index + k] = _array[sindex];
        }
    }
    
    // return occupation on a square
    // results an array of width x height elements
    // scratch a scratch array of (width x height) elements
    void gets(int x, int y, int width, int height, int[] results)
    {
        assert(results.length == width * height);
        int wmask = this._widthMask;
        int hmask = this._heightMask;
        int wworld = this._width;
        
        // get a bigger rect of tiles (border of 1)
        
        int index = 0;
        for (int j = 0; j < height; ++j) 
        {
            int py = y + j;
            for (int i = 0; i < width; ++i) 
            {
                int px = x + i;
                results[index] = _array[((py & hmask) * wworld) + (px & wmask)];
                index += 1;
            }
        }
    }
    
    
    // return multiples tiles all at once
    // results an array of width x height elements
    // scratch a scratch array of (width + 2) x (height + 2) elements
    void getTiles(int x, int y, int width, int height, 
        ref Vec!int results, ref Vec!int scratch)
    {
        assert(results.length == width * height);
        assert(scratch.length == (width + 2) * (height + 2));
        int wp2 = width + 2;
        int wmask = this._widthMask;
        int hmask = this._heightMask;
        int wworld = this._width;
        
        // get a bigger rect of tiles (border of 1)
        
        int index = 0;
        int wp1 = width + 1;
        int hp1 = height + 1;
        int i, j;
        
        for (j = -1; j < hp1; ++j) 
        {
            for (i = -1; i < wp1; ++i) 
            {
                int px = x + i;
                int py = y + j;
                scratch[index] = _array[((py & hmask) * wworld) + (px & wmask)]; //wrap around
                index += 1;
            }
        }
        
        // compose tiles without fearing boundaries thanks to the border
        int nindex = 0;
        int scratchIndex = width + 3;
        
        for (j = 0; j < height; j++) 
        {
            for (i = 0; i < width; i++) 
            {
            
                int centerTile = scratch[scratchIndex];
                //if (centerTile > 8) 
                //{
                //    centerTile = 1 + (centerTile - 1) & 7;
                //}
                
                if (centerTile <= 0) 
                {
                    results[nindex] = centerTile - 1;
                }
                else 
                {
                    int up = scratch[scratchIndex - wp2];
                    int down = scratch[scratchIndex + wp2];
                    int left = scratch[scratchIndex - 1];
                    int right = scratch[scratchIndex + 1];
                    
                    int r = 0;
                    if (centerTile == up) 
                    {
                        r += /* tron.SLOT_UP */ 1;
                    }
                    if (centerTile == down) 
                    {
                        r += /* tron.SLOT_DOWN */ 2;
                    }
                    if (centerTile == left) 
                    {
                        r += /* tron.SLOT_LEFT */ 4;
                    }
                    if (centerTile == right) 
                    {
                        r += /* tron.SLOT_RIGHT */ 8;
                    }
                    
                    results[nindex] = r + 16 * (centerTile - 1);
                }
                nindex += 1;
                scratchIndex += 1;
            }
            scratchIndex += 2;
        }
        
    }
    
    bool isSafePos(int x, int y, int dir)
    {
        int dx = directionX(dir);
        int dy = directionY(dir);
  		int empty = /* tron.WORLD_EMPTY */ 0;
		for (int i = 0; i < 30; ++i)
		{
			int p = this.get(x + dx * i, y + dy * i);
			if (p != empty) 
			{
				return false;
			}
		}
		return true;
    }
    
    // fill a line on the world to prevent early crossings
    void line(int x, int y, int dir, int what)
    {
        int dx = directionX(dir);
        int dy = directionY(dir);  
		for (int i = 0; i < 30; ++i)
		{
			this.set(x + dx * i, y + dy * i, what);
		}			
    }

    
    // return an array of objects with x, y and dir
    void getSafePositions(int n, ref Vec!SafePos results)
    {
        int i, posx, posy, pdir;

        results.clearContents();
        
        for (i = 0; i < n; ++i)
        {
	        // find a safe spot
            do
            {
                posx = randInt(0, this._width);
                posy = randInt(0, this._height);
                pdir = randInt(/* tron.DIR_UP */ 0, /* tron.DIR_RIGHT */ 3 + 1);
                
            } while(!this.isSafePos(posx, posy, pdir));
            
            this.line(posx, posy, pdir, /* tron.WORLD_WALL_BLUE */ -5);
            
            // change the track
            
            results.pushBack( SafePos(posx, posy, pdir) );
        }
        
        // clear all lines done during search
        for (i = 0; i < n; ++i)
        {
        	this.line(results[i].x, results[i].y, results[i].dir, /* tron.WORLD_EMPTY */ 0);
    	}
    }   
   
}

static struct SafePos
{
    int x, y, dir;
}