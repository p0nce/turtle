module turtle.ui.checkbox;

import turtle.ui.widget;

class Checkbox : Widget
{
    RGBA holeColor = RGBA(30, 30, 30, 255);
    RGBA checkColorOff = RGBA(0, 0, 0, 0);
    RGBA checkColorOn = RGBA(128, 239, 128, 255);


    this(IUIContext context, bool initialValue)
    {
        super(context);
        _value = initialValue;
    }

    override Size promptSize(BoxConstraints constraints)
    {
        Size ideal = Size(30, 30);

        return constraints.constrain(ideal);
    }  

    override void draw(Canvas* canvas)
    {
        float x = 0;
        float y = 0;
        float holeRadius = getHeight();
        float checkRadius = holeRadius * 0.5f;

        canvas.fillStyle = holeColor;
        canvas.fillRect(x, y, holeRadius, holeRadius);

        canvas.fillStyle = _value ? checkColorOn : checkColorOff;
        canvas.fillRect(x + (holeRadius - checkRadius)*0.5f, y + (holeRadius - checkRadius)*0.5f, checkRadius, checkRadius);
    }

    void setValue(bool value)
    {
        _value = value;
    }

    bool getValue()
    {
        return _value;
    }

    void onSetValue(bool newValue) // called when set from UI
    {
        // override this to change behaviour of slider
    }

    override ClickOutcome onMouseClick(float x, float y, MouseButton button, bool isDoubleClick)
    {
        _value = !_value;
        onSetValue(_value);
        return ClickOutcome.consumed;
    }


private:    
    bool _value;    
}