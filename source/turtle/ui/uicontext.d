module turtle.ui.uicontext;

import dplug.core.nogc;
import turtle.ui.widget;

interface IUIContext
{
    void setMouseOver(Widget elem);
    void setFocused(Widget focused);
    void beginDragging(Widget element);
    void stopDragging();

    Widget draggedElement();
    Widget focusedElement();
    Widget mouseOverElement();

    Font getFont();
}

/// UIContext contains the "globals" of the UI. Every widget points to it.
/// it also holds the "model" of your application: an application-specific object that is
/// a global to all your widgets.
final class UIContext : IUIContext
{
public:

    /// Create an `UIContext`.
    /// This is a global object referenced to by every widget.
    this(Object model = null)
    {
        _model = model;
        _defaultFont = mallocNew!Font( cast(ubyte[]) import("Lato-Semibold-stripped.ttf"));
    }

    ~this()
    {
        destroyFree(_defaultFont);
        _defaultFont = null;
    }

    Font getFont()
    {
        return _defaultFont;
    }

    /// Returns: app-specific application model. 
    Object model()
    {
        return _model;
    }

    /// Sets the app-specific application model. 
    void model(Object m)
    {
        _model = m;
    }

    override Widget draggedElement()
    {
        return dragged;
    }
    
    override Widget focusedElement()
    {
        return focused;
    }

    override Widget mouseOverElement()
    {
        return mouseOver;
    }

    override void setMouseOver(Widget elem)
    {
        Widget old = this.mouseOver;
        Widget new_ = elem;
        if (old is new_)
            return;

        if (old !is null)
            old.onMouseExit();
        this.mouseOver = new_;
        if (new_ !is null)
            new_.onMouseEnter();
    }

    override void setFocused(Widget focused)
    {
        Widget old = this.focused;
        Widget new_ = focused;
        if (old is new_)
            return;

        if (old !is null)
            old.onFocusExit();
        this.focused = new_;
        if (new_ !is null)
            new_.onFocusEnter();
    }

    override void beginDragging(Widget element)
    {
        stopDragging();
        dragged = element;
        dragged.onBeginDrag();
    }

    override void stopDragging()
    {
        if (dragged !is null)
        {
            dragged.onStopDrag();
            dragged = null;
        }
    }

private:
    /// Last clicked element.
    Widget focused = null;

    /// Currently dragged element.
    Widget dragged = null;

    /// Currently mouse-over'd element.
    Widget mouseOver = null;

    /// The "model" of the application, in order to have a MVC / undo / centralizd handling. 
    Object _model;


    Font _defaultFont;
}