module turtle.ui.slider;

import turtle.ui.widget;

enum SliderOrientation
{
    horz,
    vert,
}

class VerticalSlider : Slider
{
    this(IUIContext context, float initialValue)
    {
        super(context, SliderOrientation.vert, initialValue);
    }
}

class HorizontalSlider : Slider
{
    this(IUIContext context, float initialValue)
    {
        super(context, SliderOrientation.horz, initialValue);
    }
}

class Slider : Widget
{
    float handleRadius = 14;
    RGBA handleColor = RGBA(104, 104, 104, 255);
    RGBA handleColorMouseOver = RGBA(158, 158, 158, 255);
    RGBA handleColorDragged = RGBA(239, 239, 239, 255);

    float lineWidth = 8;
    

    this(IUIContext context, SliderOrientation orient, float initialValue)
    {
        super(context);
        _orient = orient;
        _value = initialValue;
        _initialValue = initialValue;
    }

    bool isVertical()
    {
        return _orient == SliderOrientation.vert;
    }

    override Size promptSize(BoxConstraints constraints)
    {
        Size ideal;
        if (isVertical)
            ideal = Size( handleRadius * 2, handleRadius * 18);
        else
            ideal = Size( handleRadius * 18, handleRadius * 2);

        return constraints.constrain(ideal);
    }

    vec2f pointStart()
    {    
        float m = isVertical ? getWidth() : getHeight;
        return vec2f(m/2, m/2);
    }

    vec2f pointEnd()
    {            
        float m = isVertical ? getWidth() : getHeight;
        if (isVertical)
            return vec2f(m/2, getHeight() - m/2);
        else
            return vec2f(getWidth() - m/2, m/2);
    }

    override void draw(Canvas* canvas)
    {
        RGBA hc = handleColor;
        if (isDragged) hc = handleColorDragged;
        if (isMouseOver) hc = handleColorMouseOver;

        
        vec2f start = pointStart();
        vec2f end = pointEnd();
        vec2f current = pointStart() * (1 - _value) + end * _value;

        canvas.fillStyle = RGBA(hc.r, hc.g, hc.b, hc.a / 2);
        fillLine(*canvas, start, end, lineWidth);

        canvas.fillStyle = hc;
        canvas.fillCircle(current.x, current.y, handleRadius); // draw handle   
    }

    void setValue(float value)
    {
        assert(value >= 0 && value <= 1);
        _value = value;
    }

    float getValue()
    {
        return _value;
    }

    void onSetValue(float newValue) // called when set from UI
    {
        // override this to change behaviour of slider
    }

    override ClickOutcome onMouseClick(float x, float y, MouseButton button, bool isDoubleClick)
    {
        if (isDoubleClick)
        {
            _value = _initialValue;
            onSetValue(_value);
            return ClickOutcome.consumed;
        }
        return ClickOutcome.drag;
    }

    float extent()
    {
        vec2f start = pointStart();
        vec2f end = pointEnd();
        return 1 + start.distanceTo(end);
    }

    // Called when mouse drag this Element.
    // This function is meant to be overriden.
    override void onMouseDrag(float x, float y, float dx, float dy)
    {
        float newValue = _value + (isVertical ? dy : dx) / extent();
        if (newValue < 0) newValue = 0;
        if (newValue > 1) newValue = 1;
        if (newValue != _value)
        {
            _value = newValue;
            onSetValue(_value);
        }
    }



private:
    SliderOrientation _orient;
    float _value = 0.5f;    
    float _initialValue;
}