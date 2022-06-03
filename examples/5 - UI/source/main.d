import turtle;

int main(string[] args)
{
    runGame(new UIExample);
    return 0;
}

class UIExample : TurtleGame
{
    float posx = 0;
    float posy = 0;

    override void load()
    {
        setBackgroundColor( color("#2d2d30") );
        setTitle("UI example");

        root.addChild(_mainPanel = new MainPanel(uiContext));
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape"))
        {
            exitGame;
        }
    }

    override void resized(float width, float height)
    {
        _mainPanel.setPosition( box2f.rectangle(0, 0, width, height) );
    }

    override void mouseMoved(float x, float y, float dx, float dy)
    {
        _lastMouseX = x;
        _lastMouseY = y;
        _mainPanel.provokeMouseMove(x, y, dx, dy, false);
    }

    override void mousePressed(float x, float y, MouseButton button, int repeat)
    {
        _mainPanel.provokeMouseClick(x, y, button, repeat > 1);
    }

    override void mouseWheel(float wheelX, float wheelY)
    {
        _mainPanel.provokeMouseWheel(_lastMouseX, _lastMouseY, wheelX, wheelY);
    }

    override void mouseReleased(float x, float y, MouseButton butto)
    {
        uiContext.stopDragging(); // TODO move to turtle
    }

    override void draw()
    {
        // Draw normal stuff
        // Draw UI

        // 1. raw drawing
        _mainPanel.rawDrawAndDrawChildren(0, 0, framebuffer());      

        // 2. canvas drawing
        root.drawOnCanvas(canvas);

        // 3. box positions
        debug if (_debugBox) _mainPanel.displayPositions(0, 0, framebuffer());
    }

private:
    MainPanel _mainPanel;

    debug bool _debugBox = false;

    float _lastMouseX = 0.0f;
    float _lastMouseY = 0.0f;
}


class MainPanel : Row
{
public:
    this(IUIContext uiContext)
    {
        super(uiContext);

        setCrossAxisAlignment(CrossAxisAlignment.start);

        _column = new Column(uiContext);
        _column.setCrossAxisAlignment(CrossAxisAlignment.stretch);
    }

private:
    Column _column;
}

