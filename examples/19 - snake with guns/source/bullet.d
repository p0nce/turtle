module bullet;

import world;
import constants;
import audiomanager;
import game;
import player;

struct Bullet
{
    int _posx = -1;
    int _posy = -1;
    int _movx = -1;
    int _movy = -1;
    int _state = BULLET_STATE_DEAD;
    int _power = 2;

    void init(int x, int y, int dx, int dy, int power)
    {
        this._posx = x;
        this._posy = y;
        this._movx = dx;
        this._movy = dy;
        this._state = BULLET_STATE_ALIVE;
        if (power < 2) power = 2;
        if (power > 10) power = 10;
        this._power = power;
    }
    
    void update(int widthMask, 
                int heightMask, 
                World* world, 
                AudioManager audioManager)
    {
        if (this._state == BULLET_STATE_ALIVE) 
        {
            int newposx = (this._posx + this._movx) & widthMask;
            int newposy = (this._posy + this._movy) & heightMask;
            
            int here = world.get(newposx, newposy);
            
            if (here > 0 || here < -2) 
            {
                this._state = BULLET_STATE_EXPLODING1;
                
                // sound
                audioManager.playSampleLocation(SAMPLE_EXPLODE, 1.0, newposx, newposy);
            }           
            this._posx = newposx;
            this._posy = newposy;
        }
    }
    
    void undraw(World* world)
    {
        if (this._state == BULLET_STATE_ALIVE) 
        {
            world.set(this._posx, this._posy, WORLD_EMPTY);
        }
    }
    
    void draw(World* w) 
    {
        int i, j;
        int state = this._state;
        if (state == BULLET_STATE_DEAD) 
        {
            return;
        }
        int x = this._posx;
        int y = this._posy;
        //var w = this._world;      
        
        if (state == BULLET_STATE_ALIVE)
        {
            w.set(x, y, WORLD_BULLET);
        }
        else
        {
            int c;
            if (state == 2) c = -1;
            if (state == 3) c = -2;
            if (state == 4) c = 0;
            int p = this._power;
            
            if (p == 2)
            {
                w.setSecure(x    , y - 2, c);
                w.setSecure(x - 1, y - 1, c);
                w.setSecure(x    , y - 1, c);
                w.setSecure(x + 1, y - 1, c);
                w.setSecure(x - 2, y    , c);
                w.setSecure(x - 1, y    , c);
                w.setSecure(x    , y    , c);
                w.setSecure(x + 1, y    , c);
                w.setSecure(x + 2, y    , c);                   
                w.setSecure(x - 1, y + 1, c);
                w.setSecure(x    , y + 1, c);
                w.setSecure(x + 1, y + 1, c);
                w.setSecure(x    , y + 2, c);
            }
            else
            {
                for (j = -p; j <= p; j++) 
                {
                    int l = p - abs_int(j);
                    for (i = -l; i <= l; i++) 
                    {
                        w.setSecure(x + i, y + j, c);                       
                    }
                }
            }
            this._state++;
        }
    }
}

enum int MAX_BULLETS = 128;

class BulletPool
{
    Bullet[] _bullets;
    Game _game;
    int _count;

    this(Game game)
    {
        _game = game;
        _bullets.length = MAX_BULLETS;
        _count = 0;
    }

    void addBullet(int x, int y, int dx, int dy, int power)
    {
        if (this._count < MAX_BULLETS) 
        {
            this._bullets[this._count].init(x, y, dx, dy, power);
            this._count++;
        }
    }

    void update()
    {
        int length = this._count;
        World* world = _game.world;
        AudioManager audioManager = _game.audioManager;
        int widthMask = world._widthMask;
        int heightMask = world._heightMask;
        Bullet[] bullets = this._bullets;
        int i = 0;
        for (i = 0; i < length; i++) 
        {
            bullets[i].update(widthMask, heightMask, world, audioManager);
        }
    }

    void draw()
    {
        int length = this._count;
        Bullet[] bullets = this._bullets;
        World* world = _game.world;
        for (int i = 0; i < length; i++) 
        {
            bullets[i].draw(world);
        }
    }

    void undrawAndClean()
    {
        int i = 0;
        Bullet[] bullets = this._bullets;
        int count = this._count;
        World* world = _game.world;
        
        for (i = 0; i < count; i++) 
        {
            bullets[i].undraw(world);
        }     
           
        i = 0;
        while (i < count) 
        {
            Bullet bi = bullets[i];
            int state = bi._state;
            if (state == BULLET_STATE_DEAD) 
            {
                count--;                
                // swap with last element
                Bullet temp = bi;
                bullets[i] = bullets[count];
                bullets[count] = temp;
            }
            else 
            {
    //          if (state === BULLET_STATE_ALIVE)
    //          {
    //              bi.undraw(world);   
    //          }
                i++;
            }
        }
        this._count = count;
    }
}
    

struct Camera
{
    int _x, _y;
    int _movx, _movy;
    int _wx, _wy;

    this(Game game, int x, int y)
    {
        this._x = x;
        this._y = y;
        this._movx = 0;
        this._movy = 0;
        this._wx = game.world._width;
        this._wy = game.world._height;
    }

    void follow(Player player, int dx, int dy)
    {
        int oldx = this._x;
        int oldy = this._y;
        int wx = this._wx;
        int wy = this._wy;
        int wmask = wx - 1;
        int ymask = wy - 1;
        int newx = (player._posx + dx) & wmask;
        int newy = (player._posy + dy) & ymask;
        
        int movx = newx - oldx;
        int movy = newy - oldy;
        
        this._x = newx;
        this._y = newy;
        
        //var wx = this._world._width;
        //var wy = this._world._height;
        
        while (movx < -2) 
        {
            movx += wx;
        }
        while (movx > +2) 
        {
            movx -= wx;
        }
        while (movy < -2) 
        {
            movy += wy;
        }
        while (movy > +2) 
        {
            movy -= wy;
        }
        this._movx = movx;
        this._movy = movy;      
    }   
}
