module game;

import dplug.core.vec;
import constants;
import audiomanager;
import world;
import pattern;
import player;
import texture;
import bullet;
import player;
import viewport;

class Game
{
    this(TextureManager textures, AudioManager audioManager, int size, int nHumans)
    {
        _audioManager = audioManager;

        // 6 : 64x64
        // 7 : 128x128
        // 8 : 256x256
        // 9 : 512x512
        _world = World(size, size);
        _nHumans = nHumans;
        _textures = textures;

/*
        if (patternManager)
        {
            patternManager.addPatterns(this._world, Math.round(this._world._width * this._world._height / 2000.0)); // 4000.0
        }
        */


        _players.length = MAX_PLAYERS;
        _bulletPool = new BulletPool(this);
    
        Vec!SafePos safePos;
        // choose safe locations (assume existing)
        _world.getSafePositions(MAX_PLAYERS, safePos);
    
        for (int i = 0; i < MAX_PLAYERS; i++) 
        {
            bool isHuman = i == 0; // one player support only
            int team = i + 1;
            _players[i] = new Player(this, isHuman, team, safePos[i].x, safePos[i].y, safePos[i].dir);
        }
    
         // create viewports
        _viewports.length = MAX_PLAYERS;
        for (int i = 0; i < MAX_PLAYERS; ++i) 
        {
            this._viewports[i] = new Viewport(this, this._players[i], _world.width, _world.height);
        }
    
        audioManager.setWorldSize(_world._width, _world._height);
    
        _endState = END_NOT_YET;
        _endElapsed = 0;
    }

    World* world() { return &_world; }
    AudioManager audioManager() { return _audioManager; }
    BulletPool bulletPool() { return _bulletPool; }

private:

    int _endState;
    int _endElapsed;
    int _nHumans;

    World _world;
    AudioManager _audioManager;
    BulletPool _bulletPool;
    TextureManager _textures;

    Player[] _players;
    Viewport[] _viewports;
}

/+
    
    
};

tron.Game.prototype = {
	
	update: function()
    {
        // move all players
        var players = this._players;
        var bulletPool = this._bulletPool;
        //var N = this._nPlayers;
        var nHumans = this._nHumans;
        var viewports = this._viewports;
        var i;
        
        
        for (i = 0; i < /*N*/ 8; ++i)
        {
            players[i].intelligence();
        }
        
        
        //bulletPool.undraw();
        //bulletPool.clean();
        bulletPool.undrawAndClean();
        
        // move all players
        for (i = 0; i < /*N*/ 8; ++i)
        {
            players[i].update(false);
        }
        
        bulletPool.update();
 //       bulletPool.checkDeath();
        
        
        // check collision, mark as dead		
        for (i = 0; i < /*N*/ 8; ++i)
	    {
	    	players[i].checkDeath(false);
		}
        
        // draw players, advance explosion state		
        for (i = 0; i < /*N*/ 8; ++i)
        {
           players[i].draw(false);
        }
        
        bulletPool.update();
   //     bulletPool.checkDeath();
        bulletPool.draw();
        
        // check collision, mark as dead again		
        for (i = 0; i < /*N*/ 8; ++i)
        {
            players[i].checkDeath2(false);
        }
        
        
        // TURBO        
             
        // move all turbo players
        for (i = 0; i < nHumans; i++) 
        {
            players[i].update(true);
        }
        
        // check collision turbo players, mark as dead		
        for (i = 0; i < nHumans; i++) 
        {
            players[i].checkDeath(true);
        }    
        
         // draw players, advance explosion state		
        for (i = 0; i < nHumans; i++) 
        {
           players[i].draw(true);
        }
        
        // check collision, mark as dead again		
        for (i = 0; i < nHumans; i++) 
        {
            players[i].checkDeath2(true);
        }
        
        // END TURBO
        
        // set the audible part of the game
        var audioManager = this._audioManager;
        audioManager.clearFocus();
        for (i = 0; i < nHumans; ++i)
        {
	        var player = players[i];
	        var viewport = viewports[i];
        	audioManager.addFocus(player._posx, player._posy, (viewport._width + viewport._height) * 0.53);
    	}
    },
    
    keydown: function(evt)
    {
	    var players = this._players;
	    var nHumans = this._nHumans;
	    if (nHumans >= 1)
	    {
		    switch (evt.keyCode)
	        {
	            case 38: players[0].pushCommand(/* tron.COMMAND_UP */ 0); break;
	            case 40: players[0].pushCommand(/* tron.COMMAND_DOWN */ 1); break;
	            case 37: players[0].pushCommand(/* tron.COMMAND_LEFT */ 2); break;
	            case 39: players[0].pushCommand(/* tron.COMMAND_RIGHT */ 3); break;
	            case 48:                                                            // numpad 0 Opera
	            case 96: players[0].pushCommand(/* tron.COMMAND_SHOOT */ 6); break; // numpad 0
	        }
        }
        if (nHumans >= 2)
        {
			switch (evt.keyCode)
			{
				case 90: 
				case 87: players[1].pushCommand(/* tron.COMMAND_UP */ 0); break;
			    case 83: players[1].pushCommand(/* tron.COMMAND_DOWN */ 1); break;
			    case 81: 
			    case 65: players[1].pushCommand(/* tron.COMMAND_LEFT */ 2); break;
			    case 68: players[1].pushCommand(/* tron.COMMAND_RIGHT */ 3); break;
			    case 69: players[1].pushCommand(/* tron.COMMAND_SHOOT */ 6); break; // E
			}   
        }
        if (nHumans >= 3)
        {
			switch (evt.keyCode)
			{
				case 73: players[2].pushCommand(/* tron.COMMAND_UP */ 0); break;
			    case 75: players[2].pushCommand(/* tron.COMMAND_DOWN */ 1); break;
			    case 74: players[2].pushCommand(/* tron.COMMAND_LEFT */ 2); break;
			    case 76: players[2].pushCommand(/* tron.COMMAND_RIGHT */ 3); break;
			    case 79: players[2].pushCommand(/* tron.COMMAND_SHOOT */ 6); break;
			}   
        }
        if (nHumans >= 4)
        {
			switch (evt.keyCode)
			{
				case 36: players[3].pushCommand(/* tron.COMMAND_UP */ 0); break; // home
			    case 35: players[3].pushCommand(/* tron.COMMAND_DOWN */ 1); break; // end
			    case 46: players[3].pushCommand(/* tron.COMMAND_LEFT */ 2); break; // del
			    case 34: players[3].pushCommand(/* tron.COMMAND_RIGHT */ 3); break; // page down
			    case 57:
			    case 33: players[3].pushCommand(/* tron.COMMAND_SHOOT */ 6); break; // page up
			}   
        }
    },
    
    renderViewports: function()
    {
	    var viewports = this._viewports;
	    
	    for (var i = 0; i < 8; ++i)        
        {
            var v = viewports[i];
            if (v._isValid) 
            {
                v.moveCamera();
                v.render();
            }
        }
    },
    
    render: function()
    {
        this.renderViewports();
        
        if (this._endState === /* tron.END_NOT_YET */ 0)
        {
	         // check terminationed
	    	//var nPlayers = this._nPlayers;
		    var nHumans = this._nHumans;
	        var nPlayersAlive = /* nPlayers */ 8;  
	        var nHumansAlive = nHumans;  
	        var players = this._players;
	         
	        for (i = 0; i < /*nPlayers*/8; ++i)
	        {
	            if (players[i]._state === /* tron.STATE_DEAD */ 6)
	            {
		            nPlayersAlive--;
		            if (i < nHumans) 
		            {
			            nHumansAlive--;
		            }
	            }
	        } 
	        var nAIAlive = nPlayersAlive - nHumansAlive;
	        if (nPlayersAlive === 0)
	        {
		        this._endState = /* tron.END_EVERYONE_IS_DEAD */ 1;
		        
	        } else {
		        
		        if ((nAIAlive === 0) && (nHumansAlive === 1))
		        {
			        this._endState = /* tron.END_PLAYER_WIN */ 3;
		        }
		        
		        if ((nHumansAlive === 0) && (nAIAlive > 0))
		        {
			        this._endState = /* tron.END_IA_WIN */ 2;
		        }
	        }
        } 
        else
        {
	        this._endElapsed++;
        }
        
        
    },
    
    resize: function(mw, mh)
    {
	    var viewports = this._viewports;
        for (var i = 0; i < 8; ++i)        
        {
            var v = viewports[i];
            if (v._isValid) 
            {
                v.resize();
            }
        }
    },
    
    
};
+/