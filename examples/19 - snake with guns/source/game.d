module game;

import turtle;
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


class SnakeGame
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
            this._viewports[i] = new Viewport(this, this._players[i], 30, 22);
        }
    
        audioManager.setWorldSize(_world._width, _world._height);
    
        _endState = END_NOT_YET;
        _endElapsed = 0;
    }

    World* world() { return &_world; }
    AudioManager audioManager() { return _audioManager; }
    BulletPool bulletPool() { return _bulletPool; }
    Player[] players() { return _players; }
    AudioManager _audioManager;
    TextureManager _textures;

    void render(ImageRef!RGBA fb)
    {
        renderViewports(fb);

        if (this._endState == END_NOT_YET)
        {
            // check terminationed
            //var nPlayers = this._nPlayers;
            int nHumans = this._nHumans;
            int nPlayersAlive = MAX_PLAYERS;  
            int nHumansAlive = nHumans;  

            for (int i = 0; i < MAX_PLAYERS; ++i)
            {
                if (_players[i]._state == STATE_DEAD)
                {
                    nPlayersAlive--;
                    if (i < nHumans) 
                    {
                        nHumansAlive--;
                    }
                }
            } 
            int nAIAlive = nPlayersAlive - nHumansAlive;
            if (nPlayersAlive == 0)
            {
                _endState = END_EVERYONE_IS_DEAD;

            } else {

                if ((nAIAlive == 0) && (nHumansAlive == 1))
                {
                    _endState = END_PLAYER_WIN;
                }

                if ((nHumansAlive == 0) && (nAIAlive > 0))
                {
                    _endState = END_IA_WIN;
                }
            }
        } 
        else
        {
            this._endElapsed++;
        }
    }

    void renderViewports(ImageRef!RGBA fb)
    {
        _viewports[0].moveCamera();
        _viewports[0].render(fb);
    }

    void keydown(string evt)
    {
        if (evt == "up") players[0].pushCommand(COMMAND_UP);
        if (evt == "down") players[0].pushCommand(COMMAND_DOWN);
        if (evt == "left") players[0].pushCommand(COMMAND_LEFT);
        if (evt == "right") players[0].pushCommand(COMMAND_RIGHT);
        if (evt == "space") players[0].pushCommand(COMMAND_SHOOT);
    }

    void update()
    {
        
        int nHumans = _nHumans;
       
        for (int i = 0; i < MAX_PLAYERS; ++i)
        {
            players[i].intelligence();
        }

        bulletPool.undrawAndClean();

        // move all players
        for (int i = 0; i < MAX_PLAYERS; ++i)
        {
            players[i].update(false);
        }

        bulletPool.update();

        // check collision, mark as dead		
        for (int i = 0; i < MAX_PLAYERS; ++i)
        {
            players[i].checkDeath(false);
        }

        // draw players, advance explosion state		
        for (int i = 0; i < MAX_PLAYERS; ++i)
        {
            players[i].draw(false);
        }

        bulletPool.update();
        bulletPool.draw();

        // check collision, mark as dead again		
        for (int i = 0; i < MAX_PLAYERS; ++i)
        {
            players[i].checkDeath2(false);
        }


        // TURBO        

        // move all turbo players
        for (int i = 0; i < nHumans; i++) 
        {
            players[i].update(true);
        }

        // check collision turbo players, mark as dead		
        for (int i = 0; i < nHumans; i++) 
        {
            players[i].checkDeath(true);
        }    

        // draw players, advance explosion state		
        for (int i = 0; i < nHumans; i++) 
        {
            players[i].draw(true);
        }

        // check collision, mark as dead again		
        for (int i = 0; i < nHumans; i++) 
        {
            players[i].checkDeath2(true);
        }

        // END TURBO

        audioManager.clearFocus();
        for (int i = 0; i < nHumans; ++i)
        {
            Player player = players[i];
            Viewport viewport = _viewports[i];
            audioManager.addFocus(player._posx, player._posy, (viewport._width + viewport._height) * 0.53);
        }
    }

private:

    int _endState;
    int _endElapsed;
    int _nHumans;

    World _world;    
    BulletPool _bulletPool;

    Player[] _players;
    Viewport[] _viewports;
}

/+
    
    
};

tron.Game.prototype = {
	
	
    
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
+/