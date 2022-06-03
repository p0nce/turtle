import turtle;
static import std.random;
import std.string;
import std.random;


int main(string[] args)
{
    runGame(new MarkovExample);
    return 0;
}

struct MarkovModel
{
    string possibleValues;
    MarkovRule[] rules;

    bool isAllowed(char ch)
    {
        return possibleValues.indexOf(ch) != -1;
    }
}

struct MarkovRule
{
    string replace;
    string byThat;    
}

enum ModelType
{
    fill,
    growth,
    maze,
    randomWalk,
    loopErasedRandomWalk,
    aldousBroderMaze,
    mazeBacktracer
}

enum int ModelCount = ModelType.max + 1;

MarkovModel getModel(ModelType type)
{
    final switch(type)
    {
        case ModelType.fill:
            return MarkovModel("BW", [ MarkovRule("B", "W") ] );

        case ModelType.growth:
            return MarkovModel("BW", [ MarkovRule("WB", "WW") ] );

        case ModelType.maze:
            return MarkovModel("BWA", [ MarkovRule("WBB", "WAW") ] );

        case ModelType.randomWalk:
            return MarkovModel("RBW", [ MarkovRule("RBB", "WWR") ] );

        case ModelType.loopErasedRandomWalk:
            return MarkovModel("RBWGU", 
                               [ 
                                MarkovRule("RBB", "WWR"),
                                MarkovRule("RBW", "GWP"),
                                MarkovRule("PWG", "PBU"),
                                MarkovRule("UWW", "BBU"),
                                MarkovRule("UWP", "BBR")
                                ] );
        case ModelType.aldousBroderMaze:
            return MarkovModel("RBW", 
                               [ 
                                MarkovRule("RBB", "WWR"),
                                MarkovRule("R*W", "W*R")
                               ] );

        case ModelType.mazeBacktracer:
            return MarkovModel("RBGW", 
                               [ 
                                MarkovRule("RBB", "GGR"),
                                MarkovRule("RGG", "WWR")
                               ] );
    }
}

enum GX = 19;
enum GY = 19;
enum ANIM_FRAME = 0.05;
/*
<color symbol="E" value="008751" rgb="0 135 81" name="Emerald"/>
<color symbol="N" value="AB5236" rgb="171 82 54" name="browN"/>
<color symbol="D" value="5F574F" rgb="95 87 79" name="Dead"/>
<color symbol="A" value="C2C3C7" rgb="194 195 199" name="Alive"/>
<color symbol="W" value="FFF1E8" rgb="255 241 232" name="White"/>
<color symbol="R" value="FF004D" rgb="255 0 77" name="Red"/>
<color symbol="O" value="FFA300" rgb="255 163 0" name="Orange"/>
<color symbol="Y" value="FFEC27" rgb="255 236 39" name="Yellow"/>
<color symbol="G" value="00E436" rgb="0 228 54" name="Green"/>
<color symbol="U" value="29ADFF" rgb="41 173 255" name="blUe"/>
<color symbol="S" value="83769C" rgb="131 118 156" name="Slate"/>
<color symbol="K" value="FF77A8" rgb="255 119 168" name="pinK"/>
<color symbol="F" value="FFCCAA" rgb="255 204 170" name="Fawn"/>*/


RGBA toColor(char ch)
{
    switch(ch)
    {
        case 'B': return RGBA(0, 0, 0, 255);
        case 'I': return RGBA(29, 43, 83, 255);
        case 'P': return RGBA(126, 37, 83, 255);
        case 'W': return RGBA(255, 241, 232, 255);
        case 'R': return RGBA(255, 0, 77, 255);
        case 'Y': return RGBA(255, 236, 39, 255);
        case 'G': return RGBA(0, 228, 54, 255);
        case 'A': return RGBA(194, 195, 199, 255);
        case 'U': return RGBA(41, 173, 255, 255);
        default:
           assert(false);
    }
}

bool isInGrid(int x, int y)
{
    return x >= 0 && y >= 0 && x < GX && y < GY;
}  

// The state grid
struct Grid
{
    char[GX][GY] content;

    void makeNewGrid(ref MarkovModel model)
    {
        for (int y = 0; y < GY; ++y)
        {
            for (int x = 0; x < GX; ++x)
            {
                content[y][x] = 'B';
            }
        }
        if (model.isAllowed('R'))
            content[GY/2][GX/2] = 'R';
        else if (model.isAllowed('W'))
            content[GY/2][GX/2] = 'W';
    }
}

// A match position
struct MarkovMatch
{
    int x, y, dx, dy; // origin and direction
}

class MarkovExample : TurtleGame
{
    override void load()
    {
        setBackgroundColor( RGBA(30, 30, 30, 255) );
        changeModel(0);
    }

    override void update(double dt)
    {     
        if (keyboard.isDown("return")) grid.makeNewGrid(_model);
        if (keyboard.isDown("escape")) exitGame;
        if (keyboard.isDown("left") && _accumDt >= 0)
        {
            changeModel(-1);
            _accumDt = -0.25;
        }
        if (keyboard.isDown("right") && _accumDt >= 0)
        {
            _accumDt = -0.25;
            changeModel(1);
        }

        _accumDt += dt;

        while (_accumDt > ANIM_FRAME)
        {
            _accumDt -= ANIM_FRAME;
            stepMarkov(grid, _model, rng);
        }
    }

    override void resized(float width, float height)
    {
        _WX = windowWidth();
        _WY = windowHeight();
        double SX = cast(int)(_WX / (GX + 2));
        double SY = cast(int)(_WY / (GY + 2));
        _S = SX < SY ? SX : SY;
        _marginX = (_WX - _S*GX)/2;
        _marginY = (_WY - _S*GY)/2;
    }

    // Note: this use both the canvas and direct frame buffer access (for text)
    override void draw()
    {
        ImageRef!RGBA fb = framebuffer();     

        with(canvas)
        {
            save();

            translate(_marginX , _marginY);
            scale(_S, _S);

            for (int y = 0; y < GY; ++y)
            {
                for (int x = 0; x < GX; ++x)
                {
                    char ch = grid.content[y][x];

                    save();

                    double margin = 0.05;
                    translate(x + margin, y + margin);
                    scale(1.0 - margin*2);

                    fillStyle = toColor(ch);
                    fillRect(0, 0, 1, 1);

                    restore;
                }
            }
        }                
    }  

    void changeModel(int offset)
    {
        int t = _type + offset;
        while(t < 0)
            t += ModelCount;
        while(t >= ModelCount)
            t -= ModelCount;

        _type = cast(ModelType)t;
        _model = getModel(_type);
        grid.makeNewGrid(_model);
    }

   

private:

    MarkovModel _model;
    ModelType _type  = ModelType.loopErasedRandomWalk;

    Grid grid;

    int _sx = -1, _sy = -1;
    float _WX, _WY, _S, _marginX, _marginY;

    double _accumDt = 0;

    Random rng;    
}

MarkovMatch[] allMatchesForThisRule(ref Grid grid, ref MarkovRule rule)
{
    MarkovMatch[] r = [];

    void tryMatch(int x, int y, int dx, int dy)
    {
        auto m = MarkovMatch(x, y, dx, dy);
        if ( isMatching(grid, rule, m))
        {
            r ~= m;
        }
    }

    for (int y = 0; y < GY; ++y)
    {
        for (int x = 0; x < GX; ++x)
        {
            tryMatch(x, y, 1, 0);
            tryMatch(x, y, -1, 0);
            tryMatch(x, y, 0, 1);
            tryMatch(x, y, 0, -1);
        }
    }
    return r; // Note: huge GC consumption here.
}

// Applies the model to the grid
void stepMarkov(ref Grid grid, ref MarkovModel model, ref Random rng)
{
    foreach(rule; model.rules)
    {
        MarkovMatch[] allMatches = allMatchesForThisRule(grid, rule);

        if (allMatches !is null)
        {
            MarkovMatch thisOne = allMatches.choice(rng);
            applyMatch(grid, rule, thisOne);
            return;
        }
    }
    // Find all match for each rule.
}

bool isMatching(ref Grid grid, ref MarkovRule rule, MarkovMatch match)
{
    int len = cast(int)rule.replace.length;
    for (int n = 0; n < len; ++n)
    {
        int x = match.x + match.dx * n;
        int y = match.y + match.dy * n;
        if (!isInGrid(x, y))
            return false;
        char refChar = rule.replace[n];
        if (refChar != '*' && (grid.content[y][x] != rule.replace[n]))
            return false;
    }
    return true;
}

void applyMatch(ref Grid grid, ref MarkovRule rule, MarkovMatch match)
{
    assert(rule.replace.length == rule.byThat.length);

    int len = cast(int)rule.replace.length;
    for (int n = 0; n < len; ++n)
    {
        int x = match.x + match.dx * n;
        int y = match.y + match.dy * n;
        assert(grid.content[y][x] == rule.replace[n] || rule.replace[n] == '*');
        char replacementChar = rule.byThat[n];
        if (replacementChar != '*')
            grid.content[y][x] = replacementChar;
    }
}