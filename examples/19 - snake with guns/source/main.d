import turtle;
import textmode;
import std;

import game;
import texture;
import audiomanager;

class SnakeExample : TurtleGame
{
    TextureManager _textures;
    AudioManager _audio;
    SnakeGame _game;

    override void load()
    {
        setBackgroundColor(color("transparent"));
        console.size(30, 22);
        console.setPaletteEntry(1, 201, 36, 100, 0);
        console.setPaletteEntry(2, 91, 179, 97, 255);
        console.setPaletteEntry(3, 249, 146, 82, 255);
        console.setPaletteEntry(4, 30, 136, 117, 255);
        console.setPaletteEntry(5, 106, 55, 113, 255);
        console.setPaletteEntry(6, 155, 156, 130, 255);
        console.setPaletteEntry(7, 247, 182, 158, 255);
        console.setPaletteEntry(8, 96, 108, 129, 255); 
        console.setPaletteEntry(9, 203, 77, 104, 255);
        console.setPaletteEntry(10, 161, 229, 90, 255);
        console.setPaletteEntry(11, 247, 228, 118, 255);
        console.setPaletteEntry(12, 17, 173, 193, 255); 
        console.setPaletteEntry(13, 244, 140, 182, 255);
        console.setPaletteEntry(14, 109, 247, 193, 255);
        console.setPaletteEntry(15, 255, 255, 255, 255);

        _audio = new AudioManager(1337); // fake object

        _textures = new TextureManager(3);
        _textures.add("img/players4.png");
        _textures.add("img/otherstiles.png");
        _textures.add("img/eyes.png");

        //newGame();
        time = 0;
        needRender = true;
        needRenderBackground = true;
    }

    enum double FPS = 12;
    enum double TIME_PER_FRAME = 1.0 / FPS;
    double time;
    bool needRender;
    bool needRenderBackground;

    override void resized(float width, float height)
    {
        needRenderBackground = true;
    }

    override void update(double dt)
    {
        console.update(dt);
        if (keyboard.isDownOnce("escape")) exitGame();

        // original game work with fixed physics
        if (dt > 1)
            dt = 1;

        time += dt;
        while(time > TIME_PER_FRAME)
        {
            time -= TIME_PER_FRAME;
            if (_game) 
            {
                _game.update();
                needRender = true;
            }
        }        
    }

    override void draw()
    {
        ImageRef!RGBA fb = framebuffer();

        if (needRenderBackground)
        {
            RGBA bg = RGBA(255, 255, 255, 255);
            framebuffer.fillAll(bg);
            needRenderBackground = false;
        }

        if (needRender)
        {
            if (_game) _game.render(framebuffer);
            needRender = false;
        }

        uiRender(console);
    }

    void newGame()
    {
        _game = new SnakeGame(_textures, _audio, 7, 1);
    }

    override void keyPressed(KeyConstant key)
    {
        uiKeydown(console, key);            
        if (_game) _game.keydown(key);
    }

    // <begin>tiny immediate text UI

    void uiRender(TM_Console* console)
    {
        TextUI ui;
        ui.console = console;
        ui.keypressed = false;        
        consoleDraw(ui);
    }

    void uiKeydown(TM_Console* console, KeyConstant k)
    {
        TextUI ui;
        ui.console = console;
        ui.keypressed = true;        
        ui.key = k;
        consoleDraw(ui); // possibly something changed
        // redraw without the keychange
        ui.keypressed = false;
        ui.key = "unsupported";
        consoleDraw(ui);
    }

    struct TextUI
    {
        TM_Console* console;
        bool keypressed = false; // true if key pressed
        KeyConstant key = "unknown";
        bool pressed(KeyConstant key)
        {
            return keypressed && this.key == key;
        }
    }

    void showArrow(ref TextUI ui)
    {
        ui.console.print("→ ");
    }

    // Widget menu.
    /// Returns: selected entry. -1 if none.
    int menu(ref TextUI ui,
             ref int menuIndex,
             int col, int row, 
             const(char)[][] labels)
    {
        int N = cast(int)labels.length;
        if (ui.pressed("down")) 
            menuIndex = (menuIndex + 1) % N;
        if (ui.pressed("up"))
            menuIndex = (menuIndex - 1 + N) % N;

        /*
        // mouse over
        if (sd.clicked || sd.moved)
        {
            for (int n = 0; n < N; ++n)
            {
                int minCol = col;
                int w = 23;//cast(int)labels[n].length + 4;
                int minRow = row + n * 2;
                int h = 2;

                if (sd.mouse(minCol, minRow, w, h))
                {
                    if (sd.clicked || sd.moved)
                    {
                        menuIndex = n;
                    }
                    if (sd.clicked)
                        return menuIndex; // will draw just after
                }
            }
        }
        */

        console.save;
        for (int n = 0; n < N; ++n)
        {
            console.locate(col, row + n * 2);
            if (menuIndex == n)
                console.fg(TM_colorYellow);
            else
                console.fg(TM_colorGrey);
            if (menuIndex == n)
            {
                console.print("  ");
                console.style = 0;
            }
            else
            {
                console.print("  ");
                console.style = 0;
            }
            console.bg(TM_colorBlack);
            console.print(labels[n]);
            console.bg(TM_colorBlack);
        }
        console.restore;

        if (ui.pressed("return"))
        {
            return menuIndex;
        }
        else
        {
            return -1;
        }
    }

    enum State
    {
        mainmenu,
        shop,
        gameHUD,
    }

    // <only game data to save>
    int dollars = 0;
    // </only game data to save>

    State state = State.mainmenu;
    int mainmenuSelect = 0;
   
    void consoleDraw(ref TextUI ui)
    {
        ui.console.cls;
        if (state == State.mainmenu)
        {
            mainmenu(ui);
        }
        else if (state == State.shop)
        {
            //shop(ui);
        }
        else if (state == State.gameHUD)
        {
            gameHUD(ui);
        }
    }

    void mainmenu(ref TextUI ui)
    {
        int sel = menu(ui, mainmenuSelect,
                       1, 1,
                       ["Start game", "Shop", "Exit"]);
        if (sel == -1)

        if (sel == 2)
        {
            exitGame();
        }
        if (sel == 0)
        {
            newGame();
            state = State.gameHUD;
        }
        if (sel == 1)
        {
            // TODO
        }
    }

    void gameHUD(ref TextUI ui)
    {
        ui.console.print(format("Points: %s", dollars));
        // exit this state if no human survived
    }
}

int main(string[] args)
{
    runGame(new SnakeExample());
    return 0;
}