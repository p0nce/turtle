module audiomanager;

import core.stdc.math: sqrt;

class AudioManager
{
	double _time;
	int _worldWidthMask;
	int _worldHeightMask;
	int _worldHalfWidth;
	int _worldHalfHeight;
	int _nFocus;
	int[4] _x;
	int[4] _y;
	int[4] _dist;

	this(int dummy)
	{

	}	

/+
// thanks http://perevodik.net/en/posts/22/

tron.AudioManager = function()
{
	var temp = document.createElement('audio');
	this._audioTagSupport = !!(temp.canPlayType);
	
	if (this._audioTagSupport)
	{
		var mp3 = temp.canPlayType('audio/mpeg;');
		this._MP3Support = (mp3 !== '') && (mp3 !== 'no');
		
		var ogg = temp.canPlayType('audio/ogg; codecs="vorbis"');
		this._OGGSupport = (ogg !== '') && (ogg !== 'no');
		
		//var aac = temp.canPlayType('audio/x-m4a;') || temp.canPlayType('audio/aac;')  || temp.canPlayType('audio/x-aac;');
		//this._AACSupport = (aac !== '') && (aac !== 'no');
		//this._WAVSupport = temp.canPlayType('audio/wav; codecs="1"');
		//this._AACSupport = temp.canPlayType('audio/x-m4a;') || temp.canPlayType('audio/aac;');
	}
	else
	{
		
		this._MP3Support = false;
		this._OGGSupport = false;
		
		//this._AACSupport = false;
		//this._WAVSupport = false;
		//this._AACSupport = false;
	}
	
	this._possible = this._MP3Support || this._OGGSupport;
	this._musics = new Array(10);
	this._samples = new Array(10);
	
	this._musicCount = 0;
	this._sampleCount = 0;
	this._current = -1; // no music playing
	
	// number of point of focus
	this._nFocus = 0;
	
	
	this._x = new Array(4);
	this._y = new Array(4);
	this._dist = new Array(4);
	
	this._worldWidthMask = 1023;
	this._worldHeightMask = 1023;
	this._worldHalfWidth = 512;
	this._worldHalfHeight = 512;
	this._currentTitle = "";
	this._time = 0;
	this._disabled = false;
	
	var fillArray = tron.fillArray;
	fillArray(this._x, 0);
	fillArray(this._y, 0);
	fillArray(this._dist, 0);
};
+/
	
	void updateTime(double dt)
	{
		this._time += dt;	
	}
	
	void setWorldSize(int w, int h)
	{
		this._worldWidthMask = (w - 1);
		this._worldHeightMask = (h - 1);
		this._worldHalfWidth = w >> 1;
		this._worldHalfHeight = h >> 1;
	}
	
	/+
	void addMusic(title, ogg, mp3, volume)
	{
		if (!this._possible) return;
		var sound;
		
		var musicAreStreamed = true;
		
		if (this._OGGSupport && (ogg !== "") )
		{
			sound = new tron.Sound(title, ogg, musicAreStreamed, volume);
			
			this._musics[this._musicCount] = sound;
			this._musicCount++;
		}
		else if (this._MP3Support  && (mp3 !== ""))
		{
			sound = new tron.Sound(title, mp3, musicAreStreamed, volume);
			
			this._musics[this._musicCount] = sound;
			this._musicCount++;
		}		
	},
	+/

	/+
	
	addSample : function(ogg, mp3, volume, channels)
	{
		if (!this._possible) return;
		
		if (this._OGGSupport && (ogg !== "") )
		{
			this._samples[this._sampleCount] = new tron.Sample(ogg, volume, channels);
			this._sampleCount++;
		}
		else if (this._MP3Support  && (mp3 !== ""))
		{
			this._samples[this._sampleCount] = new tron.Sample(mp3, volume, channels);
			this._sampleCount++;
		}		
	},
	+/
	
	// play a sample
	void playSample(int i, double volume)
	{
		/*
		if (!this._possible) return;
		if (this._disabled) { return false; }
		var s = this._samples[i];
		var t = this._time;
		return this._samples[i].play(t, volume);
		*/
	}
	
	// play a sample with distance attenuation (crude)
	void playSampleLocation(int i, double volume, int x, int y)
	{
		/*
		if (!this._possible) return;
		if (this._disabled) { return false; }
			
		var volume = this.getVolumeFromLocation(x, y) * volume;
		
		if (volume > 0.0001) 
		{
			var t = this._time;
			this._samples[i].play(t, volume);
		}
		*/
	}
	
	void clearFocus()
	{
		this._nFocus = 0;		
	}
	
	void addFocus(int x, int y, int dist)
	{
		/*
		var i = this._nFocus++;
		this._x[i] = x;
		this._y[i] = y;
		this._dist[i] = dist;*/
	}
	
	double getVolumeFromLocation(int x, int y)
	{
		double res = 0.0;
		int N = this._nFocus;
		int[4] fx = this._x;
		int[4] fy = this._y;
		int[4] fd = this._dist;
		int wx = this._worldWidthMask;
		int wy = this._worldHeightMask;
		int w2 = this._worldHalfWidth;
		int h2 = this._worldHalfHeight;
		for (int i = 0; i < N; ++i)
		{
			int dx = ((fx[i] + w2 + wx - x) & wx) - w2;
			int dy = ((fy[i] + h2 + wy - y) & wy) - h2;
			int dist = fd[i];
			double volume = 1.0 - sqrt(dx * dx + dy * dy) / dist;
			if (volume > res) 
			{
				res = volume;
			}
		}
		return res;		
	}
	
	/+
	// plays next music if needed
	nextMusic : function()
	{
		if (!this._possible) { return false; }
		if (this._disabled) { return true; }
		
		var t = this._time;
		
		if (this._musicCount > 0)
		{
			if ((this._current == -1)  || (!this._musics[this._current].isPlaying()))
			{			
				this._current = (this._current + 1) % this._musicCount;			
				var currentMusic = this._musics[this._current];
				currentMusic.play(t, 1.0);
				this._currentTitle = currentMusic._title;
				return true;				
			}
		}		
		return false;
	},
	
	enableSounds : function()
	{
		this._disabled = false;
		
		if (this._musicCount > 0)
		{
			if ((this._current != -1)  && (this._musics[this._current].isPlaying()))
			{			
				var currentMusic = this._musics[this._current];
				currentMusic.unmute();							
			}
		}
	},
	
	disableSounds : function()
	{
		if (!this._possible) return false;
		
		if (this._musicCount > 0)
		{
			if ((this._current != -1)  && (this._musics[this._current].isPlaying()))
			{			
				var currentMusic = this._musics[this._current];
				currentMusic.mute();				
				return true;				
			}
		}
		this._disabled = true; 
		return false;
	},
	
	// return true if all music can be playexd and all sampels can be played through
	allLoaded: function()
	{
		var i;
		var musics = this._musics;
		for (i = 0; i < this._musicCount; ++i)
		{
			if (!musics[i].isLoaded())
			{
				return false;
			}
		}
		var samples = this._samples;
		for (i = 0; i < this._sampleCount; ++i)
		{
			if (!samples[i].isLoaded())
			{
				return false;
			}
		}		
		return true;
	},
	
	loadedCount: function()
    {
        var i;
        var res = 0;
        var musics = this._musics;
		for (i = 0; i < this._musicCount; ++i)
		{
			if (!musics[i].isLoaded())
			{
				res++;
			}
		}
		var samples = this._samples;
		for (i = 0; i < this._sampleCount; ++i)
		{
			if (!samples[i].isLoaded())
			{
				res++;
			}
		}		
		return res;
    },
    
    count: function()
    {
		return this._musicCount + this._sampleCount;
    },
        
    progression: function()
    {
        return this.loadedCount() / this.count();
    }/*,
    
    checkEnded : function()
    {
	    var samples = this._samples;
	    var sampleCount = this._sampleCount;
	    for (var i = 0; i < sampleCount; ++i)
		{
			samples[i].checkEnded();
		}
    }*/

    +/
    
}