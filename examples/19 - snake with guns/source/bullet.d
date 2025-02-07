module bullet;

import world;
import constants;
import audiomanager;



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
                AudioManager* audioManager)
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
};


