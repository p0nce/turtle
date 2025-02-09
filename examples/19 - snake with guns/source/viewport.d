module viewport;

import bullet;
import game;
import texture;
import player;
import world;

// Stateful thing whose task is to display the surroundings of a player
// It owns a Camera to that purpose.
// originally used complex caching to avoid HTML5 Canvas redraw
class Viewport
{
    this(Game game, Player player, int w, int h)
    {
        _width = w;
        _height = h;
        _game = game;
        _world = game.world;
        _camera = Camera(game, 0, 0);
        _textures = game._textures;

        _playersTexture = _textures.get(TEXTURE_PLAYERS);
        _otherTexture   = _textures.get(TEXTURE_OTHERTILES);
        _eyesTexture    = _textures.get(TEXTURE_EYES);
        _barTexture     = _textures.get(TEXTURE_BAR);

         moveCamera();
    }

    void moveCamera()
    {
        _camera.follow(this._player, -(_width >> 1), -(_height >> 1));
    }


    Game _game;
    World* _world;
    Camera _camera;
    Image* _playersTexture;
    Image* _otherTexture;
    Image* _eyesTexture;
    Image* _barTexture;
}

/+
tron.Viewport.prototype = {

    render: function()
    {
        //var game = this._game;
        var camera = this._camera;
        var textures = this._textures;
        var context = this._context;
        var world = this._world;
        var player = this._player;
        var camx = camera._x;
        var camy = camera._y;
        
        var playersimg = this._playersTexture._img;
        var othersimg = this._otherTexture._img;
        var eyesimg = this._eyesTexture._img;
        var barimg = this._barTexture._img;
        
        //var playerstiles = this._playersTexture._tiles;
        //var othertiles = this._otherTexture._tiles;
        
        
        var varray = this._array;
        var narray = this._newArray;
        var scratch = this._scratch;
        
        var tx = this._width;
        var ty = this._height;
        var x, y, i, j, k, i16, j16;
        var index = 0;
        var newOne, oldOne, camovx, camovy;
        var justResized = this._justResized;
        this._justResized = false;
        
        
        // optionnal !
        // slower except on edge case where it's faster
        // less latency overall, more predictability
        if (this._copyOptimization && (!justResized)) 
        {
            camovx = camera._movx;
            camovy = camera._movy;
            
            if (camovx || camovy) 
            {
                // copy to scratch
                index = 0;
                for (i = tx * ty; i--;) 
                {
                    scratch[index] = varray[index];
                    index += 1;
                }
                
                for (j = 0; j < ty; j++) 
                {
                    var sy = j + camovy;
                    for (i = 0; i < tx; i++) 
                    {
                        var sx = i + camovx;
                        
                        if (sx >= 0 && sy >= 0 && sx < tx && sy < ty) 
                        {
                            varray[i + tx * j] = scratch[sx + tx * sy];
                        }
                    }
                }
                
                this._auxContext.drawImage(this._canvas, 0, 0);
                /*
                var cx = (tx - 2) * 16;
                var cy = (ty - 2) * 16;
                var bx = 16 * (1 + camovx);
                var by = 16 * (1 + camovy);
                */
                
                var cx = (tx - 2) * 16;
                var cy = (ty - 2) * 16;
                var bx = -16 * (camovx);
                var by = -16 * (camovy);
                context.drawImage(this._auxCanvas, bx, by);//, cx, cy, 16, 16, cx, cy);
            }
        }
        
        // get tiles to display
        world.getTiles(camx, camy, tx, ty, narray, scratch);
        
        var EMPTY_TILE = /* tron.EMPTY_TILE */ -1;
        context.fillStyle = '#eaf5ff';        
        
        // optionnal EMPTY optimization
        // draw rectangle of color
        // actually slower
       /* 
        var optimizeEmptyTiles = true;
        if (optimizeEmptyTiles) 
        {	        
	        camovx = camera._movx;
            camovy = camera._movy;
            var hozMajor = Math.abs(camera._movx) < Math.abs(camera._movy);
            
            if (camera._movx === 0) // horizontal lines of empty
            {
	            index = 0;
	            for (j = 0; j < ty; j++) 
		        {
		            for (i = 0; i < tx; i++) 
		            {
			            for (k = 0; k < tx - i; ++k)
			            {
				            newOne = narray[index + k];
               				oldOne = varray[index + k];
               				if (newOne !== EMPTY_TILE) break;	
               				if (oldOne === EMPTY_TILE) break;               				
               				varray[index + k] = newOne;
			            }
			            
			            if (k > 0)
			            {
				            i16 = i * 16;
                    		j16 = j * 16;
				            context.fillRect(i16, j16, 16 * k, 16);
				            i += (k - 1);
				            index += (k - 1);				            
			            }
			            index++;
		        	}
		        }
	        }
	        else if (camera._movy === 0)  // vertical lines of empty
	        {
		        for (i = 0; i < tx; i++) 
		        {
		            for (j = 0; j < ty; j++) 
		            {
			            for (k = 0; k < ty - j; ++k)
			            {
				            index = (j + k) * tx + i;
				            newOne = narray[index];
               				oldOne = varray[index];
               				if (newOne !== EMPTY_TILE) break;	
               				if (oldOne === EMPTY_TILE) break;               				
               				varray[index] = newOne;
			            }
			            
			            if (k > 0)
			            {
				            i16 = i * 16;
                    		j16 = j * 16;
				            context.fillRect(i16, j16, 16, 16 * k);
				            j += (k - 1);				            			            
			            }
		        	}
		        }
	        }
        } 
        */
           
        
        if (player)   
        {
	        varray[tx - 4] = 0;
	        varray[tx - 3] = 0;
	        varray[tx - 2] = 0;
	        varray[tx - 1] = 0; 
	        varray[tx * 2 - 1] = 0;
	        varray[tx * 2 - 2] = 0;
	        varray[tx * 3 - 1] = 0;
	        varray[tx * 3 - 2] = 0;	        
        }
        
        if (justResized) // draw all tiles
        {
			for (i = 0; i < tx * ty; ++i)
			{
				varray[i] = 0;
			}			
    	}    	
    	
        var players = this._players;
        var nPlayers = players.length;
        var ww = world._widthMask;
        var wh = world._heightMask;
        
        // force player eye erasure        
        if (player._state === /* tron.STATE_ALIVE */ 1) 
        {
	        x = (player._posx - camx) & ww;
            y = (player._posy - camy) & wh;
            if ((x >= 0) && (x < tx) && (y >= 0) && (y < ty))
            {
	            varray[x + y * tx] = 0;
            }
        }
        
        // draw changing tiles	        
        index = 0;
        
        for (j = 0; j < ty; j++) 
        {
            for (i = 0; i < tx; i++) 
            {
                newOne = narray[index];
                oldOne = varray[index];
                
                if (oldOne !== newOne) // draw only when necessary
                {
                    i16 = i * 16;
                    j16 = j * 16;                    
                   
                    if (newOne > /* EMPTY_TILE */ -1) 
                    { 	                                        
                        y = (newOne & 0x70); // select row base on team
                        x = (newOne & 15) * 16;
                        context.drawImage(playersimg, x , y, 16, 16, i16, j16, 16, 16);
                    }                    
                    else if (newOne < /* EMPTY_TILE */ -1) 
                    {                        
                        x = ((-newOne - 2) /* & 15*/ ) * 16;
                        context.drawImage(othersimg, 0, x, 16, 16, i16, j16, 16, 16);
                    }
                    else
                    {
                       context.fillRect(i16, j16, 16, 16);
                    }
                    
                    varray[index] = newOne;
                    
                }
                index += 1;
            }
        }
        
      // draw players eyes
        for (i = 0; i < nPlayers; ++i)
        {
			/* draw eyes of players that are visible */
			var tplayer = players[i];
            if (tplayer._state === /* tron.STATE_ALIVE */ 1) 
            {
                x = (tplayer._posx - camx) & ww;
                y = (tplayer._posy - camy) & wh;
                j = 16 * tplayer._dir;
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
                    context.drawImage(eyesimg, 0, j | 0, 16, 16, x * 16, y * 16, 16, 16);
                }			
            }			
        }
        
        if (player && (player._human))
        {
	        context.drawImage(barimg, tx * 16 - 32, 0);
        	var barLength = player.shootPixels();
        	
        	
        	context.fillStyle = (barLength === 0) ? '#20ff20' : '#ffc4e0';
        	context.fillRect(tx * 16 - 27, 6, 24 - barLength, 1);
        	
    	}
    }
};
+/