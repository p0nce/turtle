module player;

import std.random;
import dplug.core.vec;
import constants;
import game;
import world;
import bullet;


class Player
{
    int _posx;
    int _posy;
    int _movx, _movy;
    int _dir;
    SnakeGame _game;
    World* _world;
    int _state;
    int _team;
    bool _turbo = false;
    bool _human;
    bool _lastTurn;
    double _likeToTurn, _likeShooting;
    int _waitforshoot;
    int _sight;
    int _scratchSize;
    int _scratchSight;
    int _commandIndex;
    int _warning;
    int _invincibility = 0;
    int _tripleShoot = 0;  

    Vec!int _scratch;
    Vec!int _scratch2;
    Vec!int _queueData;
    Vec!int _commandQueue;

    this(SnakeGame game, bool isHuman, int team, int px, int py, int dir)
    {
        _game = game;
        _state = STATE_ALIVE;
        _turbo = false;
        _human = isHuman;
        _world = game.world;
        _posx = px;
        _posy = py;
        _team = team;
        _dir = -1; // invalid
        _movx = 1;
        _movy = 0;
        _waitforshoot = 0;
        _sight = SIGHT;

        _scratchSight = 15;
        _scratchSize = (2 * _scratchSight + 1) | 0;
        _scratch.resize(_scratchSize * _scratchSize);
        _scratch2.resize(_scratchSize * _scratchSize);    
        _queueData.resize(40 * this._scratchSize * this._scratchSize + 1);
        _likeToTurn = 0.010 + uniform(0.0, 1.0)  * 0.01;
        _likeShooting = 0.035 + 0.03 * uniform(0.0, 1.0);    
    
        _commandQueue.resize(COMMAND_QUEUE_LENGTH);    
        _commandIndex = 0; // command remaining
        setDirection(dir);
        _lastTurn = uniform(0.0, 1.0) < 0.5;
        _warning = 0;
    
        _invincibility = 0;
        _tripleShoot = 0;    
    
        for (int i = 0; i < COMMAND_QUEUE_LENGTH; ++i) 
        {
            this._commandQueue[i] = COMMAND_NONE;
        }    
        
        fillArray( this._queueData, 0);
        fillArray( this._scratch, 0);
        fillArray( this._scratch2, 0);
    }

    void setDirection(int d)
    {
        int cdir = this._dir;
        switch (d)
        {
            case /* tron.DIR_UP */ 0:
                if (cdir == /*tron.DIR_DOWN */ 1) 
                {                   
                    if (this._turbo)
                    {
                        this._turbo = false;
                    }
                    else
                    {
                        this.shoot();
                    }
                    return;
                }               
                this._movx = 0;
                this._movy = -1;
                break;
                
            case /*tron.DIR_DOWN */ 1:
                if (cdir == /* tron.DIR_UP */ 0) 
                {                   
                    if (this._turbo)
                    {
                        this._turbo = false;
                    }
                    else
                    {
                        this.shoot();
                    }
                    return;
                }
                this._movx = 0;
                this._movy = 1;
                break;
                
            case /* tron.DIR_LEFT */ 2:
                if (cdir == /* tron.DIR_RIGHT */ 3) 
                {                   
                    if (this._turbo)
                    {
                        this._turbo = false;
                    }
                    else
                    {
                        this.shoot();           
                    }
                    return;
                }
                this._movx = -1;
                this._movy = 0;
                break;
                
            case /* tron.DIR_RIGHT */ 3:
                if (cdir == /* tron.DIR_LEFT */ 2) 
                {                   
                    if (this._turbo)
                    {
                        this._turbo = false;
                    }
                    else
                    {
                        this.shoot();
                    }
                    return;
                }
                this._movx = 1;
                this._movy = 0;
                break;
            default: 
                break;
        }
        
        if ((cdir == d) && (this._human))
        {
            this._turbo = !this._turbo; 
        }
        else
        {
            this._turbo = false;    
        }
        this._dir = d;
    }


    void shoot()
    {
        if (this._waitforshoot == 0) 
        {
            if (this._invincibility > 0) return;
            int movx = this._movx;
            int movy = this._movy;
            World* world = this._world;
            int widthMask = world._widthMask;
            int heightMask = world._heightMask;
            int mx = (this._posx + movx) & widthMask;
            int my = (this._posy + movy) & heightMask;          
            BulletPool bpool = _game.bulletPool;
            int tripleShoot = this._tripleShoot;
            int power = tripleShoot + 1;
            int mx2, my2, mx3, my3;
            bpool.addBullet(mx, my, movx, movy, power);
            if (this._tripleShoot > 0)
            {
                mx2 = (this._posx - movy) & widthMask;
                my2 = (this._posy + movx) & heightMask;
                if (world.get(mx2, my2) == 0)
                {
                    bpool.addBullet(mx2, my2, movx, movy, power);
                }
                mx3 = (this._posx + movy) & widthMask;
                my3 = (this._posy - movx) & heightMask;
                if (world.get(mx3, my3) == 0)
                {
                    bpool.addBullet(mx3, my3, movx, movy, power);
                }
            }
            this._waitforshoot = /* tron.BULLET_DELAY */ 40;
            
            // bullet sound
            this._game._audioManager.playSampleLocation(/* tron.SAMPLE_SHOOT */ 0, 1.0, mx, my);
        }
    }

    void turnLeft()
    {
        setDirection(turnLeftDirection(_dir));
    }

    void turnRight()
    {
        setDirection(turnRightDirection(_dir));
    }

    int direction2command()
    {
        switch (this._dir)
        {
            case DIR_UP:
                return COMMAND_UP;
            case DIR_DOWN:
                return COMMAND_DOWN;
            case DIR_LEFT:
                return COMMAND_LEFT;
            case DIR_RIGHT:
                return COMMAND_RIGHT;
            default: assert(0);
        }
    }

    void executeCommand(int cmd)
    {
        switch (cmd)
        {
            case 0:
            case 1:
            case 2:
            case 3:
                this.setDirection(cmd);
                return;

            case COMMAND_TURN_LEFT:
                this.turnLeft();
                return;
            case COMMAND_TURN_RIGHT:
                this.turnRight();
                return;
            case COMMAND_SHOOT:
                this.shoot();
                return;   

            default:
                assert(false);
        }       
    }

    void pushCommand(int cmd)
    {
        if (_state != STATE_ALIVE)
            return;
        if (_commandIndex < 40) // not full ?
            _commandQueue[_commandIndex++] = cmd;
    }

    int popCommand()
    {
        int res = _commandQueue[0];
        _commandIndex--;
        int remaining = _commandIndex;
        for (int i = 0; i < remaining; ++i) 
        {
            _commandQueue[i] = _commandQueue[i + 1];
        }
        return res;
    }

    // one game tick
    void update(bool turboCycle)
    {
        if (this._state != STATE_ALIVE) 
        {
            return;
        }
        if (turboCycle && !(_turbo)) return;

        _waitforshoot = _waitforshoot - 1;
        if (_waitforshoot<0) _waitforshoot = 0;

        if (this._commandIndex > 0.5) 
        {
            if (turboCycle)
            {
                this._commandIndex = 0; // erase all commands
            }   
            else
            {
                int cmd = this.popCommand();
                this.executeCommand(cmd);
            }
        }
        World* world = _world;
        int widthMask = world._widthMask;
        int heightMask = world._heightMask;

        int newx = (this._posx + this._movx) & widthMask;
        int newy = (this._posy + this._movy) & heightMask;
        int warning = this._warning;
        int incoming = world.get(newx, newy);

        if ((warning < 2) 
            && (incoming != 0) 
            && (incoming != WORLD_FIREY) // explosions do not block
            && (incoming != WORLD_FIRER) // explosions do not block
            && (_invincibility == 0))
        {
            warning++;  
            this._turbo = false;
        }       
        else
        {
            this._posx = newx;          
            this._posy = newy;
            warning = 0;
        }
        _warning = warning;
    }

    /* check one */
    void checkDeath(bool turboCycle)
    {
        if (this._state != /* tron.STATE_ALIVE */ 1) 
        {
            return;
        }       
        if (turboCycle && !(this._turbo)) return;
        if (this._warning > 0) return;

        int t = this._world.get(this._posx, this._posy);

        if (t != 0) 
        {
            this.take(t);
        }
    }

    /* check two */
    void checkDeath2(bool turboCycle)
    {
        if (this._state != /* tron.STATE_ALIVE */ 1) 
        {
            return;
        }       
        if (turboCycle && !(this._turbo)) return;       
        if (this._warning > 0) return;
        int t = this._world.get(this._posx, this._posy);

        if (t != this._team) 
        {
            this.die();
        }
    }

    void die()
    {
        if (this._invincibility > 0) return;

        if (/* tron.PLAYERS_DO_EXPLODE */ 1) 
        {
            this._state = /* tron.STATE_EXPLODING1 */ 2;
            // die sound
            this._game._audioManager.playSampleLocation(/* tron.SAMPLE_DIE */ 2, 1.0, this._posx, this._posy);
        }
        else 
        {
            this._state = /* tron.STATE_DEAD */ 6;
        }
    }

    void draw(bool turboCycle)
    {
        if (turboCycle && !(this._turbo)) return;
        int i, j, invincibility, debris;
        int x = this._posx;
        int y = this._posy;
        World* w = this._game.world;

        switch (this._state)
        {
            case /* tron.STATE_ALIVE */ 1:              
                invincibility = this._invincibility;
                if ((invincibility > 0) && (invincibility < /* tron.INVINCIBILITY_DURATION */ 52))
                {
                    return;
                }
                w.set(x, y, this._team);
                break;

            case /* tron.STATE_EXPLODING1 */ 2:
                for (j = -2; j <= 2; j++) 
                {
                    for (i = -2; i <= 2; i++) 
                    {
                        w.setSecure(x + i, y + j, /* tron.WORLD_FIREY */ -1);
                    }
                }
                this._state = /* tron.STATE_EXPLODING2 */ 3;
                break;

            case /* tron.STATE_EXPLODING2 */ 3:
                for (j = -2; j <= 2; j++) 
                {
                    for (i = -2; i <= 2; i++) 
                    {
                        w.setSecure(x + i, y + j, /* tron.WORLD_FIRER */ -2);
                    }
                }
                this._state = /* tron.STATE_EXPLODING3 */ 4;
                break;

            case /* tron.STATE_EXPLODING3 */ 4:
            case /* tron.STATE_EXPLODING4 */ 5:


                for (j = -2; j <= 2; j++) 
                {
                    for (i = -2; i <= 2; i++) 
                    {
                        w.setSecure(x + i, y + j, /* tron.WORLD_EMPTY */ 0);
                    }
                }

                switch((this._team - 1) & 7)
                {
                    case 0: debris = /* tron.WORLD_WALL_WHITE  */ -9; break;
                    case 1: debris = /* tron.WORLD_WALL_RED    */ -11; break;
                    case 2: debris = /* tron.WORLD_WALL_VIOLET */ -13; break;
                    case 3: debris = /* tron.WORLD_WALL_PINK   */ -12; break;
                    case 4: debris = /* tron.WORLD_WALL_GREEN  */ -6; break;
                    case 5: debris = /* tron.WORLD_WALL_YELLOW */ -8; break;
                    case 6: debris = /* tron.WORLD_WALL_CYAN   */ -15; break;
                    case 7: default: debris = /* tron.WORLD_WALL_ORANGE */ -7;
                }

                for (j = -1; j <= 1; j++) 
                {
                    for (i = -1; i <= 1; i++) 
                    {   
                        w.setSecure(x + i, y + j, debris); 
                    }                   
                }
                //w.setSecure(x, y, -10);       
                this._state++;// = /* tron.STATE_DEAD */ 6;
                break;

            case /* tron.STATE_DEAD */ 6:
                break;

            default:
                assert(0);
        }
    }

    void take(int w)
    {
        if (this._invincibility > 0) 
        {
            return;
        }
        World* world = this._world;
        switch (w)
        {
            case /* tron.WORLD_POWERUP_YELLOW */ -16: 

                this._invincibility = /* tron.INVINCIBILITY_DURATION */ 52; 
                this._game._audioManager.playSampleLocation(/* tron.SAMPLE_INVINCIBLE */ 5, 1.0, this._posx, this._posy);           
                break;

            case /* tron.WORLD_POWERUP_GREEN  */ -17: 

                // get triple shoot definetively
                this._game._audioManager.playSampleLocation(/* tron.SAMPLE_WEAPON_UPGRADE */ 4, 1.0, this._posx, this._posy);
                this._tripleShoot++; 
                break;                                                    
            case /* tron.WORLD_POWERUP_PINK */ -18: 

                // teleport somewhere               
                int wx = world._width;
                int wy = world._height;
                int pdir = this._dir;

                for (int i = 0; i < 100; ++i)
                {
                    int posx = randInt(0, wx);
                    int posy = randInt(0, wy);
                    //var pdir = this._dir; randInt(/* tron.DIR_UP */ 0, /* tron.DIR_RIGHT */ 3);
                    if (world.isSafePos(posx, posy, pdir))
                    {
                        world.set(this._posx, this._posy, this._team); // eat powerup
                        this._posx = posx;
                        this._posy = posy;                      
                        //this._movx = tron.directionX(pdir);
                        //this._movy = tron.directionY(pdir);
                        //this._turbo = false;
                        //this._dir = pdir;
                        break;
                    }                       
                } 
                this._game._audioManager.playSample(/* tron.SAMPLE_TELEPORT */ 3, 1.0);
                break;

            case /* tron.WORLD_TRIANGLE_SW */ -20:
                if (this._dir == /* tron.DIR_LEFT */ 2)
                {
                    this.pushCommand(/* tron.COMMAND_UP */ 0);
                    this.pushCommand(/* tron.COMMAND_LEFT */ 2);

                } 
                else if (this._dir == /* tron.DIR_DOWN */ 1)
                {
                    this.pushCommand(/* tron.COMMAND_RIGHT */ 3);
                    this.pushCommand(/* tron.COMMAND_DOWN */ 1);
                } else this.die();
                break;

            case /* tron.WORLD_TRIANGLE_NW */ -21:  
                if (this._dir == /* tron.DIR_LEFT */ 2)
                {
                    this.pushCommand(/* tron.COMMAND_DOWN */ 1);
                    this.pushCommand(/* tron.COMMAND_LEFT */ 2);
                } 
                else if (this._dir == /* tron.DIR_UP */ 0)
                {
                    this.pushCommand(/* tron.COMMAND_RIGHT */ 3);
                    this.pushCommand(/* tron.COMMAND_UP */ 0);
                } else this.die();
                break;  


            case /* tron.WORLD_TRIANGLE_NE */ -22:
                if (this._dir == /* tron.DIR_RIGHT */ 3)
                {
                    this.pushCommand(/* tron.COMMAND_DOWN */ 1);
                    this.pushCommand(/* tron.COMMAND_RIGHT */ 3);
                } 
                else if (this._dir == /* tron.DIR_UP */ 0)
                {
                    this.pushCommand(/* tron.COMMAND_LEFT */ 2);
                    this.pushCommand(/* tron.COMMAND_UP */ 0);
                } else this.die();
                break;  

            case /* tron.WORLD_TRIANGLE_SE */ -23:  
                if (this._dir == /* tron.DIR_RIGHT */ 3)
                {
                    this.pushCommand(/* tron.COMMAND_UP */ 0);
                    this.pushCommand(/* tron.COMMAND_RIGHT */ 3);
                } 
                else if (this._dir == /* tron.DIR_DOWN */ 1)
                {
                    this.pushCommand(/* tron.COMMAND_LEFT */ 2);
                    this.pushCommand(/* tron.COMMAND_DOWN */ 1);
                } else this.die();
                break;              

            case /* tron.WORLD_POWERUP_ORANGE */ -19: break;
            default: 
                this.die();
        }
    }

    void intelligence()
    {
        if (this._state != STATE_ALIVE) 
        {
            return;
        }

        if (this._invincibility > 0)
        {
            this._invincibility--;          
        }

        if (this._human) 
        {
            return;
        }

        bool hasCommand = this._commandIndex > 0.5;

        // find time to live
        // TODO make something less dumb
        int sight = this._sight;
        int sightSide = sight;
        World* world = this._world;
        int bx = this._posx;
        int by = this._posy;
        //var x = bx;
        //var y = by;
        int mx = this._movx;
        int my = this._movy;
        alias prob = TURN_PROBABILITY;
        int index;
        int px, py, pl, pturn, minturns, minpx, minpy, minl, val2, commandPopped, iwillsurvive, ndir;

        if (hasCommand)
        {
            /* If the AI has command, we only check that we don't run into something */

            // check next location
            commandPopped = this._commandQueue[0];          
            iwillsurvive = true;
            switch (commandPopped)
            {
                case /* tron.COMMAND_UP */ 0:
                case /* tron.COMMAND_DOWN */ 1:
                case /* tron.COMMAND_LEFT */ 2:
                case /* tron.COMMAND_RIGHT */ 3:
                    int val = world.get(bx + directionX(commandPopped), by + directionY(commandPopped));
                    iwillsurvive = ((val /* tron.EMPTY */ == 0) || (val ==  /* tron.BULLET */ -4));
                    break;

                case /* tron.COMMAND_TURN_LEFT */ 4:
                    ndir = turnLeftDirection(this._dir);
                    int val = world.get(bx + directionX(ndir), by + directionY(ndir));
                    iwillsurvive = ((val /* tron.EMPTY */ == 0) || (val ==  /* tron.BULLET */ -4));
                    break;

                case /* tron.COMMAND_TURN_RIGHT */ 5:
                    ndir = turnRightDirection(this._dir);
                    int val = world.get(bx + directionX(ndir), by + directionY(ndir));
                    iwillsurvive = ((val /* tron.EMPTY */ == 0) || (val ==  /* tron.BULLET */ -4));
                    break;

                case /* tron.COMMAND_SHOOT */ 6:
                    iwillsurvive = true;
                    break;

                default:
                    break;
            }

            if (iwillsurvive) 
            {
                return; /* exit the function safely */
            }
            else 
            {
                this._commandIndex = 0; /* clear command index */
            }
        }

        bool findAPath = uniform(0.0, 1.0) < 0.002; // occasionnally we trigger a search for an exit without a danger

        for (int i = 1; i < sight; ++i) 
        {
            int val = world.get(bx + mx * i, by + my * i);

            if (findAPath || val /* tron.EMPTY */ != 0 && val != /* tron.BULLET*/ -4)
            {
                if (findAPath || i <= 2)
                {

                    //var queue = this._queue;
                    int scratchSize = this._scratchSize | 0;
                    alias scratch = this._scratch; // scratch will store surroundings
                    alias scratch2 = this._scratch2; // scratch2 will store a path from center (with commands)
                    int ssight = this._scratchSight;
                    alias UP = COMMAND_UP;
                    alias DOWN = COMMAND_DOWN;
                    alias LEFT = COMMAND_LEFT;
                    alias RIGHT = COMMAND_RIGHT;
                    alias NONE = COMMAND_NONE;
                    int e, lastcmd;

                    int queue_start = 0;
                    int queue_stop = 0;
                    alias queue_data = this._queueData;

                    /* get surroundings */
                    world.gets(bx - ssight, by - ssight, scratchSize, scratchSize, scratch[]);

                    // fill scratch 2 
                    for (int k = 0; k < scratchSize * scratchSize; ++k) 
                    {
                        scratch2[k] = NONE;
                    }

                    index = (ssight | 0) * scratchSize + (ssight | 0);

                    scratch2[index] = this._dir; //this.direction2command();

                    // push initial element
                    queue_data[queue_stop++] = ssight | 0; // x
                    queue_data[queue_stop++] = ssight | 0; // y
                    queue_data[queue_stop++] = 0; // generations
                    queue_data[queue_stop++] = 0; // number of turns
                    //queue_stop = (queue_stop + 4) | 0;

                    //var total = 1;
                    //var log_push = false;

                    for (int iter = 0; iter < ssight; iter++) 
                    {
                        /* if (log_push) console.log("iter = " + iter + "   queue contains " + (queue_stop - queue_start) / 4 + " items"); */
                        /* if empty we lost the search */
                        if (queue_start == queue_stop) 
                        {
                            /* console.log("breaking"); */
                            break;
                        }

                        /* peek head element */
                        px = queue_data[queue_start] | 0;
                        py = queue_data[queue_start + 1] | 0;
                        pl = queue_data[queue_start + 2] | 0;
                        pturn = queue_data[queue_start + 3] | 0;
                        lastcmd = scratch2[px * scratchSize + py] | 0;


                        while (pl == iter) 
                        {
                            queue_start = (queue_start + 4) | 0;

                            if ((lastcmd != RIGHT) && (px > 0)) 
                            {
                                index = 0 | (((px - 1) | 0) + scratchSize * (py | 0));
                                if (scratch2[index] == NONE) // not visited
                                {
                                    val2 = scratch[index];
                                    if ((val2 /* tron.EMPTY */ == 0) || (val2 == /* tron.BULLET*/ -4))
                                    {
                                        queue_data[queue_stop++] = (px - 1) | 0;
                                        queue_data[queue_stop++] = py;
                                        queue_data[queue_stop++] = (iter + 1) | 0;
                                        queue_data[queue_stop++] = 0 | (pturn + ((lastcmd == LEFT) ? 0 : 1));
                                        scratch2[index] = LEFT;
                                    }
                                    else 
                                    {
                                        scratch2[index] = -2; // wall
                                    }
                                }
                            }

                            if ((lastcmd != LEFT) && (px < scratchSize - 1)) 
                            {
                                index = 0 | ( ((px + 1) | 0) + scratchSize * (py | 0));
                                if (scratch2[index] == NONE) // not visited
                                {
                                    val2 = scratch[index];
                                    if ((val2 /* tron.EMPTY */ == 0) || (val2 == /* tron.BULLET*/ -4))
                                    {
                                        queue_data[queue_stop++] = (px + 1) | 0;
                                        queue_data[queue_stop++] = py;
                                        queue_data[queue_stop++] = (iter + 1) | 0;
                                        queue_data[queue_stop++] = 0 | (pturn + ((lastcmd == RIGHT) ? 0 : 1));
                                        scratch2[index] = RIGHT;
                                        /*
                                        if (log_push) console.log("push " + queue_data[queue_stop-4] + "," 
                                        + queue_data[queue_stop-3] + " gen = " + queue_data[queue_stop-2] + " turns = " + queue_data[queue_stop-1]);

                                        pushed++;
                                        */

                                    }
                                    else 
                                    {
                                        scratch2[index] = -2; // wall
                                    }
                                }
                            }

                            if ((lastcmd != DOWN) && (py > 0)) 
                            {
                                index = 0 | ((px | 0) + scratchSize * ((py - 1) | 0));
                                if (scratch2[index] == NONE) // not visited
                                {
                                    val2 = scratch[index];
                                    if ((val2 /* tron.EMPTY */ == 0) || (val2 == /* tron.BULLET*/ -4))
                                    {
                                        queue_data[queue_stop++] = px;
                                        queue_data[queue_stop++] = (py - 1) | 0;
                                        queue_data[queue_stop++] = (iter + 1) | 0;
                                        queue_data[queue_stop++] = 0 | (pturn + ((lastcmd == UP) ? 0 : 1));                                        
                                        scratch2[index] = UP;
                                        /*
                                        if (log_push) console.log("push " + queue_data[queue_stop-4] + "," 
                                        + queue_data[queue_stop-3] + " gen = " + queue_data[queue_stop-2] + " turns = " + queue_data[queue_stop-1]);

                                        pushed++;
                                        */

                                    }
                                    else 
                                    {
                                        scratch2[index] = -2; // wall
                                    }
                                }
                            }

                            if ((lastcmd != UP) && (py < scratchSize - 1)) 
                            {
                                index = 0 | ((px | 0) + scratchSize * ((py + 1) | 0));
                                if (scratch2[index] == NONE) // not visited
                                {
                                    val2 = scratch[index];
                                    if ((val2 /* tron.EMPTY */ == 0) || (val2 == /* tron.BULLET*/ -4))
                                    {
                                        queue_data[queue_stop++] = px;
                                        queue_data[queue_stop++] = (py + 1) | 0;
                                        queue_data[queue_stop++] = (iter + 1) | 0;
                                        queue_data[queue_stop++] = 0 | (pturn + ((lastcmd == DOWN) ? 0 : 1));
                                        scratch2[index] = DOWN;
                                        /*
                                        if (log_push) console.log("push " + queue_data[queue_stop-4] + "," 
                                        + queue_data[queue_stop-3] + " gen = " + queue_data[queue_stop-2] + " turns = " + queue_data[queue_stop-1]);

                                        pushed++;
                                        */

                                    }
                                    else 
                                    {
                                        scratch2[index] = -2; // wall
                                    }
                                }
                            }

                            if (queue_start == queue_stop) 
                            {
                                //console.log("empty queue breaking");
                                break;
                            }

                            /* peek another element */
                            px = queue_data[queue_start] | 0;
                            py = queue_data[queue_start + 1] | 0;
                            pl = queue_data[queue_start + 2] | 0;
                            pturn = queue_data[queue_start + 3] | 0;                            

                        }
                    }

                    // we found a way to survive ssight iterations, else fallback to normal algorithm 
                    // since we are probably fucked :)

                    /* console.log("queue has " + (queue_stop - queue_start ) / 4 + " solutions"); */

                    if (queue_start != queue_stop) 
                    {   
                        // find min number of turns
                        int iter2;
                        minturns = 1000;
                        int turns = 0;
                        for (iter2 = queue_start; iter2 < queue_stop; iter2 += 4) 
                        {

                            turns = queue_data[iter2 + 3];
                            /*                  if ((turns > 1000) || (turns < 0)) 
                            {
                            alert("W.T.F"); 
                            }
                            */                  if (turns < minturns) 
                            {
                                minturns = turns;
                                px = queue_data[iter2];
                                py = queue_data[iter2 + 1];
                                pl = queue_data[iter2 + 2];
                                /*                      if (pl !== ssight) 
                                {
                                alert("WTF man! pl is not " + ssight + " but " + pl);                                   
                                }
                                */                      if (turns < 2) 
                                {
                                    break;
                                }
                            }
                        }



                        int cmd = scratch2[(px | 0) + scratchSize * (py | 0)];
                        //              var backtrace = "(" + px + "," + py + ")";
                        int errored = false;
                        for (iter2 = 0; iter2 < pl; ++iter2) 
                        {

                            //world.set( (bx + px - ssight) | 0, (by + py - ssight) | 0, -2);
                            switch (cmd)
                            {
                                case RIGHT:
                                    scratch[iter2] = RIGHT;
                                    //                      backtrace += " => RIGHT => ";
                                    px--;
                                    break;
                                case LEFT:
                                    scratch[iter2] = LEFT;
                                    //                      backtrace += " => LEFT => ";
                                    px++;
                                    break;
                                case UP:
                                    scratch[iter2] = UP;
                                    //                      backtrace += " => UP => ";
                                    py++;
                                    break;
                                case DOWN:
                                    scratch[iter2] = DOWN;
                                    //                      backtrace += " => DOWN => ";
                                    py--;
                                    break;
                                default:
                                    // TODO FIX IT !
                                    if (!errored)
                                    {
                                        errored = true;
                                        //                          backtrace += " => ???";
                                    }
                                    // log the entire scratech 2 
                            }
                            if (!errored)
                            {
                                cmd = scratch2[px + scratchSize * py];
                            }                           
                        }

                        if ((px == ssight) && (py == ssight)) 
                        {
                            int indexmax = 0;
                            for (int iter3 = pl - 1; iter3 >= indexmax; --iter3) //pl - 1 - 10; --iter3) 
                            {
                                this.pushCommand(scratch[iter3]);
                            }
                            return;
                        }
                    }
                }

                // good enough approximation but leads to inelegant self-death
                if (uniform(0.0, 1.0) < prob[i]) 
                { // decide to turn
                    int free = i - 1;
                    int j;
                    // search left
                    int lfree = sightSide;
                    for (j = 1; j < sightSide; ++j) 
                    {
                        if (0 != world.get(bx + my * j, by - mx * j)) 
                        {
                            lfree = j - 1;
                            break;
                        }
                    }

                    // search right
                    int rfree = sightSide;
                    for (j = 1; j < sightSide; ++j) 
                    {
                        if (0 != world.get(bx - my * j, by + mx * j)) 
                        {
                            rfree = j - 1;
                            break;
                        }
                    }
                    int max = lfree > rfree ? lfree : rfree;
                    if (free <= max) 
                    {
                        if (lfree > rfree) 
                        {
                            this.pushCommand(/* tron.COMMAND_TURN_LEFT */ 4);
                            this._lastTurn = false;
                        }
                        else 
                            if (lfree < rfree) 
                            {
                                this.pushCommand(/* tron.COMMAND_TURN_RIGHT */ 5);
                                this._lastTurn = true;
                            }
                            else 
                            {
                                if (this._lastTurn)
                                {
                                    this.pushCommand(/* tron.COMMAND_TURN_LEFT */ 4);
                                    this._lastTurn = false;
                                }
                                else
                                {
                                    this.pushCommand(/* tron.COMMAND_TURN_RIGHT */5);
                                    this._lastTurn = true;
                                }                               
                            }
                    }
                }

                return;
            }
        }

        // why not turning ?
        if (uniform(0.0f, 1.0f) < this._likeToTurn) 
        {
            bool lfree2 = (0 == world.get(bx + my, by - mx));
            bool rfree2 = (0 == world.get(bx - my, by + mx));
            if (lfree2 || rfree2) 
            {
                if (!lfree2) 
                {
                    this.pushCommand(/* tron.COMMAND_TURN_RIGHT */ 5);
                }
                else 
                    if (!rfree2) 
                    {
                        this.pushCommand(/* tron.COMMAND_TURN_LEFT */ 4);
                    }
                    else 
                    {
                        this.pushCommand((uniform(0.0f, 1.0f) < 0.5) ? /* tron.COMMAND_TURN_LEFT */ 4 : /* tron.COMMAND_TURN_RIGHT */ 5);
                    }
            }
        }
        else
        {
            if (uniform(0.0f, 1.0f) < this._likeShooting) // why not shoot ?
            {
                this.pushCommand(/* tron.COMMAND_SHOOT */ 6);
            }
        }
    }
}

int turnLeftDirection(int dir)
{
    switch (dir)
    {
        case /* tron.DIR_UP */ 0:
            return /* tron.DIR_LEFT */ 2;               
        case /*tron.DIR_DOWN */ 1:
            return /* tron.DIR_RIGHT */ 3;              
        case /* tron.DIR_LEFT */ 2:
            return /*tron.DIR_DOWN */ 1;                
        case /* tron.DIR_RIGHT */ 3:
            return /* tron.DIR_UP */ 0;
        default:
            assert(false);
    }
}

int turnRightDirection(int dir)
{
    switch (dir)
    {
        case /* tron.DIR_UP */ 0:
            return /* tron.DIR_RIGHT */ 3;
        case /*tron.DIR_DOWN */ 1:              
            return /* tron.DIR_LEFT */ 2;
        case /* tron.DIR_LEFT */ 2:
            return /* tron.DIR_UP */ 0;
        case /* tron.DIR_RIGHT */ 3:
            return /*tron.DIR_DOWN */ 1;
        default:
            assert(false);
    }
}
static double[10] TURN_PROBABILITY = [-1.0, 0.999, 0.9, 0.7, 0.4, 0.3, 0.2, 0.1, 0.05, 0.025];
   
/+
   
   
    },
    
  
    
   
    
   
    
    shootPixels : function()
    {
        return 0 | Math.round(24.0 * this._waitforshoot / /* tron.BULLET_DELAY */ 40.0 );       
    }
};


+/