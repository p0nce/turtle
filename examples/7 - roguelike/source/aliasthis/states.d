module aliasthis.states;

import turtle;
import std.random;
static import std.file;

import aliasthis.simplexnoise;

import aliasthis.console,
       aliasthis.utils,
       aliasthis.config,
       aliasthis.command,
       aliasthis.lang,
       aliasthis.game;


// base class for states
class State
{
public:
    this(Console console, Lang lang)
    {
        _console = console;
        _lang = lang;
    }

    void close()
    {
    }

    // handle keypress, return next State
    State handleKeypress(KeyConstant key)
    {
        return this; // default -> do nothing
    }

    void draw(double dt)
    {
        // default: do nothing
    }

protected:
    Console _console;
    Lang _lang;
}

class Menu
{
public:
    this(string[] items)
    {
        _select = 0;
        _items = items;

        _maxLength = 0;
        for (size_t i = 0; i < items.length; ++i)
            if (_maxLength < items[i].length)
                _maxLength = cast(int)(items[i].length);
    }

    void up()
    {
        _select = (_select + _items.length - 1) % _items.length; 
    }

    void down()
    {
        _select = (_select + 1) % _items.length; 
    }

    int index()
    {
        return cast(int)_select;
    }

    void draw(int posx, int posy, Console console)
    {
        RGBA bgSelected = RGBA(110, 18, 27, 255);
        RGBA bgNormal = RGBA(6, 6, 10, 128);
        for (int y = -1; y < cast(int)_items.length + 1; ++y)
            for (int x = -2; x < _maxLength + 2; ++x)
            {
                if (y == _select)
                    console.setBackgroundColor(bgSelected);
                else
                    console.setBackgroundColor(bgNormal);

                console.putChar(posx + x, posy + y, ctCharacter!' ');
            }

        for (int y = 0; y < _items.length; ++y)
        {
            if (y == _select)
            {
                console.setForegroundColor(RGBA(255, 255, 255, 255));
            }
            else
            {
                console.setForegroundColor(RGBA(255, 182, 172, 255));
            }
            console.setBackgroundColor(RGBA(255, 255, 255, 0));
            int offset = posx + (_maxLength - cast(int)_items[y].length)/2;
            console.putText(offset, posy + y, _items[y]);
        }        
    }

private:
    string[] _items;
    size_t _select;
    int _maxLength;
}


class ConsoleFire
{
private:
    vec4f[] _color;
    int _width;
    int _height;
    SimplexNoise!Random _noise;
    double _time;

public:
    this (int width, int height)
    {
        _noise = new SimplexNoise!Random(rndGen());
        _time = 0;
        _width = width;
        _height = height;
        _color.length = _width * _height;
        _color[] = vec4f(0);
    }

    void progress(double dt)
    {
        _time += dt;
        while( _time > 0.1)
        {
            progress();
            _time -= 0.1;
        }
    }

    vec4f get(int i, int j)
    {
        return _color[i + j * _width];
    }

    void progress()
    {
        for (int j = 0; j < _height; ++j)
        {
            for (int i = 0; i < _width; ++i)
            {

            }
        }
    }
}

class StateMainMenu : State
{
private:
    Menu _menu;
    OwnedImage!RGBA _splash;
    ConsoleFire _fire;

public:

    this(Console console, Lang lang)
    {
        super(console, lang);
        _menu = new Menu( lang.mainMenuItems() );

        ubyte[] image = cast(ubyte[]) std.file.read("data/mainmenu.png");

        _splash = loadOwnedImage(image);
        
        _fire = new ConsoleFire(59, 30);
    }   

    ~this()
    {
        close();
    }

    override void close()
    {
        if (_splash !is null)
        {
            _splash.destroy();
            _splash = null;
        }
    }

    override void draw(double dt)
    {
        void getCharStyle(int x, int y, out int charIndex, out RGBA fgColor)
        {
            Xorshift rng;
            rng.seed(x + y * 80);
            int ij = uniform(0, 16, rng);
            int ci = (9 * 16 + 14);
            if (ij < 7)/*
            if (x % 2 == 0 && y % 2 == 0)*/ ci = (6 * 16 + 14);
            if (ij < 2)/*
            if (x % 4 == 0 && y % 4 == 0)*/ ci = (6 * 16 + 12);
            
            fgColor = RGBA(0, 0, 0, 235);
            charIndex = (x < 32 /*&& y > 0 && y + 1 < 32*/) ? ci : 0;
            if (y == 0 || y == 31) 
            {
                charIndex = (6 * 16 + 14);
                fgColor = RGBA(0, 0, 0, 160);
            }
        }

        _console.putImage(0, 0, _splash, &getCharStyle);

        
        _menu.draw(55, 19, _console);
       /* _fire.progress(dt);

        // draw fire
        for (int y = 1; y < 31; ++y)
        {
            for (int x = 32; x < 91; ++x)
            {   
              //  _console.setBackgroundColor(_fire.get(x - 32, y - 1));
                _console.putChar(x, y, 0);
            }
        }*/
    }

    override State handleKeypress(KeyConstant key)
    {
        // quit without confirmation
        if (key == "escape")
            return null;
        else if (key == "up")
            _menu.up();
        else if (key == "down")
            _menu.down();
        else if (key == "return")
        {
            if (_menu.index() == 0) // new game
                return new StateIntro(_console, _lang, unpredictableSeed);
            else if (_menu.index() == 1) // load game
            {
            }
            else if (_menu.index() == 2) // view recording
            {
            }
            else if (_menu.index() == 3) // change language
            {
                Lang lang;
                if (cast(LangEnglish)_lang)
                    lang = new LangFrench;
                else if (cast(LangFrench)_lang)
                    lang = new LangEnglish;

                return new StateMainMenu(_console, lang);
            }
            else if (_menu.index() == 4) // quit
            {
                return null;
            }
        }

        return this; // default -> do nothing
    }
}

class StateIntro : State
{
public:

    this(Console console, Lang lang, uint seed)
    {
        super(console, lang);       
        _seed = seed;
        _slide = 0;

        ubyte[] image = cast(ubyte[]) std.file.read("data/intro.png");
        _splash = loadOwnedImage(image);
    }    

    ~this()
    {
        close();
    }

    override void close()
    {
        if (_splash !is null)
        {
            _splash.destroy();
            _splash = null;
        }
    }

    override void draw(double dt)
    {       
   
        void getCharStyle(int x, int y, out int charIndex, out RGBA fgColor)
        {
            Xorshift rng;
            rng.seed(x + y * 80);
            int ij = uniform(0, 16, rng);
            int ci = (9 * 16 + 14);
            if (ij < 7) 
                ci = (6 * 16 + 14);
            if (ij < 2)
                ci = (6 * 16 + 12);

            fgColor = RGBA(0, 0, 0, 235);
            charIndex = (x < 16 || x >= 74) ? ci : 0;         
        }

        _console.putImage(0, 0, _splash, &getCharStyle);

        _console.setForegroundColor(RGBA(255, 182, 172, 255));
        _console.setBackgroundColor(RGBA(0, 0, 0, 0));

        _console.putFormattedText(37, 7, 40, 140, _lang.getAeneid());

        string textIntro = _lang.getIntroText()[_slide];

        _console.putFormattedText(20, 10, 51, 140, textIntro);
    }

    override State handleKeypress(KeyConstant key)
    {   
        if (key == "escape")
            return new StateMainMenu(_console, _lang);

        if (key == "left")
            _slide--;
        else
            _slide++;

        if (_slide == -1)
            return new StateMainMenu(_console, _lang);
        if (_slide == 3)
            return new StatePlay(_console, _lang, _seed);
        else
            return this;
    }

private:
    uint _seed;
    OwnedImage!RGBA _splash;
    int _slide;
}

class StatePlay : State
{
public:

    this(Console console, Lang lang, uint initialSeed)
    {
        super(console, lang);
        _game = new Game(initialSeed);
        _game.message(_lang.getEntryText());
    }    

    override void draw(double dt)
    {
        _game.draw(_console, dt);
    }

    override State handleKeypress(KeyConstant key)
    {
        Command[] commands;
        if (key == "escape")
        {
            return new StateMainMenu(_console, _lang);
        }
        else if (key == "left" || key == "KP_4")
        {
            commands ~= Command.createMovement(Direction.WEST);
        }
        else if (key == "right" || key == "KP_6")
        {
            commands ~= Command.createMovement(Direction.EAST);
        }
        else if (key == "up" || key == "KP_8")
        {
            commands ~= Command.createMovement(Direction.NORTH);
        }
        else if (key == "down" || key == "KP_2")
        {
            commands ~= Command.createMovement(Direction.SOUTH);
        }
        else if (key == "KP_7")
        {
            commands ~= Command.createMovement(Direction.NORTH_WEST);
        }
        else if (key == "KP_9")
        {
            commands ~= Command.createMovement(Direction.NORTH_EAST);
        }
        else if (key == "KP_1")
        {
            commands ~= Command.createMovement(Direction.SOUTH_WEST);
        }
        else if (key == "KP_3")
        {
            commands ~= Command.createMovement(Direction.SOUTH_EAST);
        }
        else if (key == "KP_5" || key == "space")
        {
            commands ~= Command.createWait();
        }
        else if (key == "less")
        {
            commands ~= Command.createMovement(Direction.ABOVE);
        }
        else if (key == "greater")
        {
            commands ~= Command.createMovement(Direction.BELOW);
        }
        else if (key == "u")
        {
            _game.undo();          
        }

        assert(commands.length <= 1);

        if (commands.length)
        {
            _game.executeCommand(commands[0]);
        }

        return this;
    }

private:
    Game _game;
}
