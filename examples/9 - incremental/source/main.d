import std.conv;
import std.string;
import core.stdc.stdio;
import turtle;
import dosfont;

int main(string[] args)
{
    runGame(new Incremental);
    return 0;
}


// In this incremental game, we must obtain the maximum amount of D-man.
class Incremental : TurtleGame
{
    override void load()
    {
        setBackgroundColor( color("rgb(38,38,54)") );
        setTitle("Incremental");
        points = 0;
        dmans = 0;
        farms = 0;
        factories = 0;
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;
        points += dt * 0.2 * dmans;
        dmans  += dt * 0.3 * farms;
        farms  += dt * 0.4 * factories;


        if (points >= 10)
            dmanDiscovered = true;
        if (dmans >= 2)
            farmDiscovered = true;
        if (farms >= 1)
            factoryDiscovered = true;
    }

    override void mouseMoved(float x, float y, float dx, float dy)
    {
        hovered = getClickable(x, y);
    }

    override void mousePressed(float x, float y, MouseButton button, int repeat)
    {
        if (button != MouseButton.left)
            return;
        clicked = getClickable(x, y);
        final switch(clicked) with (Clickable)
        {
            case none: break;
            case point: 
                points += 1;
                break; 
            case dman: 
                while(points >= 10)
                {
                    points -= 10;
                    dmans += 1;
                }
                break;
            case farm: 
                while(points >= 100)
                {
                    points -= 100;
                    farms += 1;
                }
                break;
            case factory: 
                while(points >= 1000)
                {
                    points -= 1000;
                    factories += 1;
                }
                break;
        }    
    }

    override void mouseReleased(float x, float y, MouseButton button)
    {
        if (button != MouseButton.left)
            return;
        clicked = Clickable.none;
    }

    Clickable hovered;
    Clickable clicked;

    enum Clickable
    {
        none,
        point,
        dman,
        farm,
        factory
    }
    double points;
    double dmans;
    double farms;
    double factories;
    bool dmanDiscovered;
    bool farmDiscovered;
    bool factoryDiscovered;

    Clickable getClickable(float x, float y)
    {
        int cx, cy;
        if (!console.windowToConsoleCoord(x, y, cx, cy))
        {
            return Clickable.none;
        }

        bool inButton(int cx)
        {
            return cx >= 3 && cx <= 31;
        }

        if (cy == 0 && inButton(cx)) 
        {
            return Clickable.point;
        }
        if (cy == 1 && inButton(cx) && points >= 10) 
        {
            return Clickable.dman;            
        }
        if (cy == 2 && inButton(cx) && points >= 100) 
        {
            return Clickable.farm;
        }

        if (cy == 3 && inButton(cx) && points >= 1000) 
        {
            return Clickable.factory;
        }
        return Clickable.none;
    }

    override void draw()
    {
        console.initialize(framebuffer, windowWidth, windowHeight);

        void resource(string name, double amount)
        {
            char[32] buf;
            sprintf(buf.ptr, "%.1f", amount);
            with(console)
            {
                col(color("#ffffff")); 
                print(name); col(color("#ffff20")); print(fromStringz(buf.ptr));
            }
        }

        void description(string s)
        {
            console.cursor(50, console.textY); 
            console.col(color("grey")); 
            console.print(s);
        }
        with(console)
        {
            cursor(0, 0);
            button("Write code                  ", hovered == Clickable.point, clicked == Clickable.point); 
            resource("LOC:    ", points);          description("Write one line of code");
            
            if (dmanDiscovered)
            {
                cursor(0, 1);
                button("Buy D-man           (10 LOC)", hovered == Clickable.dman, clicked == Clickable.dman); 
                resource("D-Man:  ", dmans);         description("Write 0.2 LOC / sec");
            }

            if (farmDiscovered)
            {
                cursor(0, 2);
                button("Buy D-man farm     (100 LOC)", hovered == Clickable.farm, clicked == Clickable.farm);
                resource("Farm:   ", farms);    description("Create 0.3 D-man / sec");
            }

            if (factoryDiscovered)
            {
                cursor(0, 3);
                button("Buy D-man factory   (1k LOC)", hovered == Clickable.factory, clicked == Clickable.factory); 
                resource("Factory:", factories); description("Create 0.4 farm / sec");
            }
        }
    }
    Console console;
}

 
// Simplified console
struct Console
{
    // Font size always 8x16
    enum int ROWS = 25;
    enum int COLUMNS = 80;
    enum int CHAR_WIDTH = 8;
    enum int CHAR_HEIGHT = 16;
    int textX;
    int textY;
    int scale = 1;
    int offsetX = 0;
    int offsetY = 0;
    RGBA textColor;
    ImageRef!RGBA frame;

    void initialize(ImageRef!RGBA frame, float windowW, float windowH)
    {
        this.frame = frame;
        this.textColor = color("white");
        this.textX = 0;
        this.textY = 0;
        int scaleX = cast(int)(windowW / (COLUMNS*CHAR_WIDTH ));
        int scaleY = cast(int)(windowH / (ROWS*CHAR_HEIGHT ));
        this.scale = scaleX < scaleY ? scaleX : scaleY;
        this.offsetX = cast(int)((windowW - scale * CHAR_WIDTH  * COLUMNS)/2);
        this.offsetY = cast(int)((windowH - scale * CHAR_HEIGHT * ROWS   )/2);
    }

    void col(RGBA c)
    {
        textColor = c;
    }

    void cursor(int x, int y)
    {
        textX = x;
        textY = y;        
    }

    void print(const(char)[] str)
    {
        frame.drawDOSText(DOSFontType.large8x16, 
                          str, 
                          textColor, 
                          offsetX + textX * scale * CHAR_WIDTH, 
                          offsetY + textY * scale * CHAR_HEIGHT,
                          0,
                          scale);
        textX += cast(int)(str.length);
    }

    void println(const(char)[] s)
    {
        print(s);
        textY += 1;
        textX = 0;
    }

    void button(const(char)[] s, bool hovered, bool clicked)
    {
        if (clicked)
            col(RGBA(255, 255, 200, 255));           
        else if (hovered)
             col(RGBA(255, 255, 0, 255));
        else
            col(RGBA(250, 250, 250, 255));

        print(" [ ");
        print(s);
        print(" ] ");
    }

    bool windowToConsoleCoord(float x, float y, out int consoleX, out int consoleY)
    {
        x -= offsetX;
        y -= offsetY;
        x /= (scale * CHAR_WIDTH);
        y /= (scale * CHAR_HEIGHT);
        int ix = cast(int)(x + 0.5);
        int iy = cast(int)(y + 0.5);
        if (ix < 0 || iy < 0 || ix >= COLUMNS || iy >= ROWS)
            return false;
        consoleX = ix;
        consoleY = iy;
        return true;
    }
}
