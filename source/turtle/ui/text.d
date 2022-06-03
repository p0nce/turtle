module turtle.ui.text;

import turtle.ui.widget;
import dplug.graphics;

class Text : Widget
{
    RGBA textColor = RGBA(255, 255, 255, 255);
    float fontSize = 25.0f;
    string content = "";    

    this(IUIContext context, string content)
    {
        super(context);
        this.content = content;
        _font = context.getFont(); // Get default font.
    }

    override Size promptSize(BoxConstraints constraints)
    {
        box2i tb = _font.measureText(content, fontSize, 0);
        Size ideal = Size(tb.width + 8, tb.height + 8);
        return constraints.constrain(ideal);
    }

    override void rawDraw(ImageRef!RGBA raw)
    {
        raw.fillText(_font, content, fontSize, 0, textColor, getWidth() * 0.5f, getHeight() * 0.5f);
    }    

private:
    Font _font;
}