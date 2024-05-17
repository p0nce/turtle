import std.conv;
import std.string;
import std.math;
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

        reset();
        prestigeAmount = 0;

    }

    void reset()
    {
        prestigeAmount += log10(points);
        points = 0;
        dmans = 0;
        farms = 0;
        factories = 0;
        _mx = -1;
        _my = -1;
        dmanThreeArms = false;
        dmanFourArms = false;
        usingVersionControl = false;
        usingSafeD = false;
    }

    double productionSlowdown()
    {
        double p = points;
        p = p - (usingVersionControl ? 1000 : 10);
        if (p < 0) p = 0;

        float slowDownFactor = 0.01;
        if (usingSafeD) slowDownFactor /= 20;
        slowDownFactor *= exp(-prestigeAmount);
        double growth = 1 /  (1.0 + p * slowDownFactor);

        // power 3/4, since there are 3 levels of slowdown but 3 or 4 of growth.
        return pow(growth, 3.0 / 4.0);
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;

        if (keyboard.isDown("return"))
        {
            // repeat last left clic
            mousePressed(_mx, _my, MouseButton.left, 1);
        }

        // in case one of the cost was enabled

        double slow = productionSlowdown();   

        double dmanFactor = 1.0;
        if (dmanThreeArms) dmanFactor = 1.5; 
        if (dmanFourArms) dmanFactor = 2;

        points += dt * 0.5 * slow * dmans;
        dmans  += dt * 0.5 * slow * farms;
        farms  += dt * 0.5 * slow * factories;

        if (points >= 10)
            dmanDiscovered = true;
        if (dmans >= 2)
            farmDiscovered = true;
        if (farms >= 1 && farmDiscovered)
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
        _mx = x;
        _my = y;
        clicked = getClickable(x, y);
        final switch(clicked) with (Clickable)
        {
            case none: 
                break;
            case point: 
                points += 1;
                break; 
            case dman: 
                while(canBeBought(dman))
                {
                    points -= 10;
                    dmans += 1;
                    lastBought = dman;
                }
                break;
            case farm: 
                while(canBeBought(farm))
                {
                    points -= 100;
                    farms += 1;
                    lastBought = farm;
                }
                break;
            case factory: 
                while(canBeBought(factory))
                {
                    points -= 1000;
                    factories += 1;
                    lastBought = factory;
                }
                break;

            case dmanUpgrade1: 
                while(canBeBought(dmanUpgrade1))
                {
                    points -= 300;
                    dmanThreeArms = true;
                    lastBought = dmanUpgrade1;
                }
                break;
            case dmanUpgrade2: 
                while(canBeBought(dmanUpgrade2))
                {
                    points -= 600;
                    dmanFourArms = true;
                    lastBought = dmanUpgrade2;
                }
                break;
            case useVersionControl:
                while(canBeBought(useVersionControl))
                {
                    points -= 2000;
                    usingVersionControl = true;
                    lastBought = useVersionControl;
                }
                break;
            case useSafeD: 
                while(canBeBought(useSafeD))
                {
                    points -= 3000;
                    usingSafeD = true;
                    lastBought = useSafeD;
                }
                break;
            case prestige: 
                while(canBeBought(prestige))
                {
                    reset();
                    lastBought = prestige;
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

    Clickable hovered; // last clickable pointed and buyable
    Clickable clicked; // clickable being bought, if any
    Clickable lastBought; // last bought item

    enum Clickable
    {
        none,
        point,
        dman,
        farm,
        factory,

        dmanUpgrade1,
        dmanUpgrade2,
        useVersionControl,
        useSafeD,
        prestige
    }
    double points;
    double dmans;
    double farms;
    double factories;
    bool dmanDiscovered;
    bool farmDiscovered;
    bool factoryDiscovered;
    float _mx, _my;

    bool dmanThreeArms;
    bool dmanFourArms;
    bool usingSafeD;
    bool usingVersionControl;
    double prestigeAmount;

    bool canBeBought(Clickable c)
    {
        final switch(c) with(Clickable)
        {
            case none:    return true;
            case point:   return true;
            case dman:    return points >= 10;
            case farm:    return points >= 100;
            case factory: return points >= 1000;

            case dmanUpgrade1: return points >= 300 && !dmanThreeArms;
            case dmanUpgrade2: return points >= 600 && dmanThreeArms && !dmanFourArms;
            case useVersionControl: return points >= 2000 && !usingVersionControl;
            case useSafeD:     return points >= 3000 && !usingSafeD;
            case prestige:     return points >= 10000;
        }
    }


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

        if (cy == 1 && inButton(cx)) return Clickable.point;
        if (cy == 2 && inButton(cx)) return Clickable.dman;            
        if (cy == 3 && inButton(cx)) return Clickable.farm;
        if (cy == 4 && inButton(cx)) return Clickable.factory;

        if (cy == 11 && inButton(cx)) return Clickable.dmanUpgrade1;
        if (cy == 12 && inButton(cx)) return Clickable.dmanUpgrade2;            
        if (cy == 13 && inButton(cx)) return Clickable.useVersionControl;
        if (cy == 14 && inButton(cx)) return Clickable.useSafeD;
        if (cy == 15 && inButton(cx)) return Clickable.prestige;

        return Clickable.none;
    }

    override void draw()
    {
        console.initialize(framebuffer, windowWidth, windowHeight);

        void resource(string name, double amount, bool extraPrecise = false)
        {
            char[32] buf;
            sprintf(buf.ptr, extraPrecise ? "%.5f" : "%.1f", amount);
            with(console)
            {
                col(color("#ffffff")); 
                print(name); col(color("#ffff20")); print(fromStringz(buf.ptr));
            }
        }

        void description(string s, Clickable which)
        {
            if (hovered == which)
            {
                console.cursor(51, console.textY); 
                console.col(color("grey")); 
                console.print(s);
            }
        }

        void button(const(char)[] s, Clickable which, bool completed = false)
        {
            with (console)
            {
                bool underMouse = hovered == which;
                bool click      = clicked == which;
                bool buyable    = canBeBought(which);
                bool wasLastBought = lastBought == which;

                if (completed)
                {
                    col(RGBA(128, 255, 128, 255));
                }
                
                else if (!buyable)
                    col(RGBA(140, 50, 50, 255));
                else if (underMouse && buyable)
                    col(RGBA(255, 255, 0, 255));
                else if (wasLastBought && buyable)
                    col(RGBA(255, 255, 200, 255));
                else
                    col(RGBA(250, 250, 250, 255));

                print(" [ ");
                print(s);
                print(" ] ");
            }
        }

        with(console)
        {
            cursor(0, 0); col(color("cyan")); print("=== PRODUCTION ===");
            cursor(0, 1);
            button("Write code                  ", Clickable.point); 
            resource("LOC:     ", points); description("Write one line of code", Clickable.point);
            
            if (dmanDiscovered)
            {
                cursor(0, 2);
                button("Buy D-man           (10 LOC)", Clickable.dman); 
                resource("D-Man:   ", dmans); description("Write 0.5 LOC / sec", Clickable.dman);
            }

            if (farmDiscovered)
            {
                cursor(0, 3);
                button("Buy D-man farm     (100 LOC)", Clickable.farm);
                resource("Farm:    ", farms); description("Create 0.5 D-man / sec", Clickable.farm);
            }

            if (factoryDiscovered)
            {
                cursor(0, 4);
                button("Buy D-man factory   (1k LOC)", Clickable.factory); 
                resource("Factory: ", factories); description("Create 0.5 farm / sec", Clickable.factory);
            }

            if (prestigeAmount > 1)
            {
                cursor(0, 5);
                resource("Prestige: ", prestigeAmount);
            }


            cursor(0, 7);
            col(color("grey"));
            print("Because of code size, your production is reduced by factor =  "); resource("", productionSlowdown, true);

            if (farms >= 2 || factories >= 1)
            {
                cursor(0, 10); col(color("cyan")); print("===  UPGRADES  ===");                
                cursor(0, 11); button("Three-armed D-mans (300 LOC)", Clickable.dmanUpgrade1, dmanThreeArms); description("50% more code", Clickable.dmanUpgrade1);
                cursor(0, 12); button("Four-armed D-mans  (600 LOC)", Clickable.dmanUpgrade2, dmanFourArms); description("again 50% more code", Clickable.dmanUpgrade2);
                cursor(0, 13); button("Use version control (2k LOC)", Clickable.useVersionControl, usingVersionControl); description("LOC slowdown begins further", Clickable.useVersionControl);
                cursor(0, 14); button("Use @safe D         (3k LOC)", Clickable.useSafeD, usingSafeD); description("Improves LOC slowdown", Clickable.useSafeD);
                cursor(0, 15); button("Rewrite it all!    (10k LOC)", Clickable.prestige); description("Improve LOC growth situation", Clickable.prestige);
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
