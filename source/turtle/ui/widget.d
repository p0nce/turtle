module turtle.ui.widget;

import dplug.core.vec;
import dplug.core.nogc;

import dplug.core;
import dplug.math;
public import dplug.graphics;
public import dplug.canvas;

public import turtle.mouse;
public import turtle.ui.size;
public import turtle.ui.boxconstraints;
public import turtle.ui.uicontext;
import turtle.node2d;


// We take the Flutter mantra "Constraints go down. Sizes go up. Parent sets position."



enum ClickOutcome
{
    ignored, // Widget did not process the click
    drag,    // Widget processed the click and started dragging
    consumed // Widget consumed the click.
}


class Widget : Node2D // base class of UI widgets
{
public:

    this(IUIContext context)
    {
        _context = context;
        _zOrderedChildren = makeVec!Widget();
    }

    /// Set relative position inside the parent.
    void setPosition(float x, float y, float width, float height)
    {
        setPosition(box2f.rectangle(x, y, width, height));
    }

    ///ditto
    void setPosition(vec2f pos, Size size)
    {
        setPosition(box2f.rectangle(pos.x, pos.y, size.width, size.height));
    }

    ///ditto
    void setPosition(float x, float y, Size size)
    {
        setPosition(box2f.rectangle(x, y, size.width, size.height));
    }

    ///ditto
    void setPosition(box2f aabb)
    {
        import std.stdio;
   //     writefln("setPosition(%s, %s , %s x %s)", aabb.min.x, aabb.min.y, aabb.width, aabb.height);
        position = aabb.min;
        if (_width != aabb.width || _height != aabb.height)
        {    
      //      writeln(" => reflowing that");
            _width = aabb.width;
            _height = aabb.height;
            reflow(); // reposition childrens if size changed
        }
    }

    /// Get relative position inside the parent.
    vec2f getPosition()
    {
        return vec2f(position.x, position.y);
    }
    
    ///ditto
    box2f getPositionRect()
    {
        return box2f.rectangle(position.x, position.y, _width, _height);
    }

    /// Get size in logical pixels.
    Size getSize()
    {
        return Size(_width, _height);
    }
  
    // Override these two virtual calls

    Size promptSize(BoxConstraints constraints)
    out (r)
    {
        assert(constraints.isSatisfiedBy(r));
    }
    do
    {
        return constraints.constrain( Size(128, 128) );
    }

    int numChildren()
    {
        return cast(int)(getChildren().length);
    }

    bool hasNoChild()
    {
        return numChildren() == 0;
    }

    bool hasOneChild()
    {
        return numChildren() == 1;
    }

    /// Returns a size constraints that says the children must be from zero to the size of the parent.
    BoxConstraints constraintInside()
    {
        return BoxConstraints.loose(Size(_width, _height));
    }

    Widget child(int n)
    {
        Node c = getChildren()[n];
        Widget w = cast(Widget)c;
        assert(w !is null);
        return w;
    }

    Widget firstChild()
    {
        return child(0);
    }

    void reflow()
    {
    }

    float getWidth()
    {
        return _width;
    }

    float getHeight()
    {
        return _height;
    }

    // Gets z-order, higher is on top
    int zOrder() pure const nothrow @nogc
    {
        return _zOrder;
    }

    void zOrder(int z) pure nothrow @nogc
    {
        _zOrder = z;
    }

    /// Returns: `true` is this widget is hovered by the mouse.
    final bool isMouseOver()
    {
        return _context.mouseOverElement is this;
    }

    /// Returns: `true` is this widget is dragged by the user.
    final bool isDragged()
    {
        return _context.draggedElement is this;
    }

    /// Returns: `true` is this widget has been last clicked.
    final bool isFocused()
    {
        return _context.focusedElement is this;
    }

    final void rawDrawAndDrawChildren(float offsetX, float offsetY, ImageRef!RGBA framebuffer)
    {
        // Find subpart of the framebuffer

        int x1 = cast(int)(offsetX + position.x);
        int y1 = cast(int)(offsetY + position.y);
        int x2 = cast(int)(offsetX + position.x + _width);
        int y2 = cast(int)(offsetY + position.y + _height);

        box2i cropBox = box2i(x1, y1, x2, y2 );
        if (cropBox.empty)
            return;

        rawDraw( framebuffer.cropImageRef(box2i(x1, y1, x2, y2 )) );
        foreach(child; getChildren())
        {
            if (auto widget = cast(Widget)child)
            {
                widget.rawDrawAndDrawChildren(offsetX + position.x, offsetY + position.y, framebuffer);
            }
        }
    }

    void rawDraw(ImageRef!RGBA raw)
    {
        // default = do nothing
    }

    final IUIContext context()
    {
        return _context;
    }

    // This function is meant to be overriden.   
    ClickOutcome onMouseClick(float x, float y, MouseButton button, bool isDoubleClick)
    {
        return ClickOutcome.ignored;
    }

    // Mouse wheel was turned.
    // This function is meant to be overriden.
    // It should return true if the wheel is handled.
    bool onMouseWheel(float x, float y, float wheelDeltaX, float wheelDeltaY)
    {
        return false;
    }

    // Called when mouse move over this Element.
    // This function is meant to be overriden.
    void onMouseMove(float x, float y, float dx, float dy)
    {
    }

    // Called when clicked with left/middle/right button
    // This function is meant to be overriden.
    void onBeginDrag()
    {
    }

    // Called when mouse drag this Element.
    // This function is meant to be overriden.
    void onMouseDrag(float x, float y, float dx, float dy)
    {
    }

    // Called once drag is finished.
    // This function is meant to be overriden.
    void onStopDrag()
    {
    }

    // Called when mouse enter this Element.
    // This function is meant to be overriden.
    void onMouseEnter()
    {
    }

    // Called when mouse enter this Element.
    // This function is meant to be overriden.
    void onMouseExit()
    {
    }

    // Called when this Element is clicked and get the focus.
    // This function is meant to be overriden.
    void onFocusEnter()
    {
    }

    // Called when focus is lost because another Element was clicked.
    // This function is meant to be overriden.
    void onFocusExit()
    {
    }

    /// Check if given point is within the widget. 
    /// Override this to disambiguate clicks and mouse-over between widgets that 
    /// would otherwise partially overlap.
    /// 
    /// `x` and `y` are given in local widget coordinates.
    /// IMPORTANT: a widget CANNOT be clickable beyond its _position.
    ///            For now, there is no good reason for that, but it could be useful
    ///            in the future if we get acceleration structure for picking elements.
    bool contains(float x, float y)
    {
        return (x >= 0 && x < _width && y >= 0 && y < _height );
    }

    // to be called at top-level when the mouse clicked
    // x,y given in local, widget coordinates.
    final bool provokeMouseClick(float x, float y, MouseButton button, bool isDoubleClick)
    {
        recomputeZOrderedChildren();

        // Test children that are displayed above this element first
        foreach(child; _zOrderedChildren[])
        {
            if (child.zOrder >= zOrder)
                if (child.provokeMouseClick(x - child.position.x, y - child.position.y, button, isDoubleClick))
                    return true;
        }

        // Test for collision with this element
        if (contains(x, y))
        {
            ClickOutcome outcome = onMouseClick(x, y, button, isDoubleClick);
            final switch(outcome) with (ClickOutcome)
            {
                case ignored: break;
                case drag: 
                {
                    _context.beginDragging(this);
                    _context.setFocused(this);
                    return true;
                }
                case consumed:
                {
                    _context.setFocused(this);
                    return true;
                }
            }
        }

        // Test children that are displayed below this element last
        foreach(child; _zOrderedChildren[])
        {
            if (child.zOrder < zOrder)
                if (child.provokeMouseClick(x - child.position.x, y - child.position.y, button, isDoubleClick))
                    return true;
        }

        return false;
    }

    // to be called at top-level when the mouse is released
    // x,y given in local, widget coordinates.
    final void provokeMouseRelease(float x, float y, MouseButton button)
    {
        _context.stopDragging();
    }

    // to be called at top-level when the mouse wheeled
    // x,y given in local, widget coordinates.
    final bool provokeMouseWheel(float x, float y, float wheelDeltaX, float wheelDeltaY)
    {
        recomputeZOrderedChildren();

        // Test children that are displayed above this element first
        foreach(child; _zOrderedChildren[])
        {
            if (child.zOrder >= zOrder)
                if (child.provokeMouseWheel(x - child.position.x, y - child.position.y, wheelDeltaX, wheelDeltaY))
                    return true;
        }

        if (contains(x, y))
        {
            if (onMouseWheel(x, y, wheelDeltaX, wheelDeltaY))
                return true;
        }

        // Test children that are displayed below this element last
        foreach(child; _zOrderedChildren[])
        {
            if (child.zOrder < zOrder)
                if (child.provokeMouseWheel(x - child.position.x, y - child.position.y, wheelDeltaX, wheelDeltaY))
                    return true;
        }

        return false;
    }

    
    // To be called when the mouse moved
    // Returns: `true` if one child has taken the mouse-over role globally.
    // UNSOLVED QUESTION: should elements receive onMouseMove even if one of the 
    // elements above in zOrder is officially "mouse-over"? Should only the mouseOver'd elements receive onMouseMove?
    // x,y given in local, widget coordinates.
    final bool provokeMouseMove(float x, float y, float dx, float dy, bool alreadyFoundMouseOver)
    {
        recomputeZOrderedChildren();

        bool foundMouseOver = alreadyFoundMouseOver;

        // Test children that are displayed above this element first
        foreach(child; _zOrderedChildren[])
        {
            if (child.zOrder >= zOrder)
            {
                bool found = child.provokeMouseMove(x - child.position.x, y - child.position.y, dx, dy, foundMouseOver);
                foundMouseOver = foundMouseOver || found;
            }
        }

        if (isDragged())
        {
            onMouseDrag(x, y, dx, dy);
        }

        if (contains(x, y)) // FUTURE: something more fine-grained?
        {
            // Get the mouse-over crown if not taken
            if (!foundMouseOver)
            {
                foundMouseOver = true;
                _context.setMouseOver(this);
            }

            onMouseMove(x, y, dx, dy);
        }

        // Test children that are displayed below this element
        foreach(child; _zOrderedChildren[])
        {
            if (child.zOrder < zOrder)
            {
                bool found = child.provokeMouseMove(x - child.position.x, y - child.position.y, dx, dy, foundMouseOver);
                foundMouseOver = foundMouseOver || found;
            }
        }
        return foundMouseOver;
    }

    void displayPositions(float offsetX, float offsetY, ImageRef!RGBA framebuffer) // debug purpose
    {
        // Find subpart of the framebuffer
        int x1 = cast(int)(offsetX + position.x);
        int y1 = cast(int)(offsetY + position.y);
        int x2 = cast(int)(offsetX + position.x + _width);
        int y2 = cast(int)(offsetY + position.y + _height);

        box2i cropBox = box2i(x1, y1, x2, y2 );
        if (!cropBox.empty)
        {
            ImageRef!RGBA myFrame = framebuffer.cropImageRef(box2i(x1, y1, x2, y2 ));
            myFrame.vline(0, 0, myFrame.h , RGBA(255, 128, 128, 255));
            myFrame.vline(myFrame.w-1, 0, myFrame.h , RGBA(255, 128, 128, 255));
            myFrame.hline(0, myFrame.w, 0, RGBA(255, 128, 128, 255));
            myFrame.hline(0, myFrame.w, myFrame.h-1, RGBA(255, 128, 128, 255));
        }

        foreach(child; getChildren())
        {
            if (auto widget = cast(Widget)child)
            {
                widget.displayPositions(offsetX + position.x, offsetY + position.y, framebuffer);
            }
        }
    }

private:
    float _width = float.nan; // NaN initialized so that the first resize calls reflow() even if size is zero
    float _height = float.nan;
    int _zOrder;
    IUIContext _context;

    /// Sorted children in Z-lexical-order (sorted by Z, or else increasing index in _children).
    Vec!Widget _zOrderedChildren;

    // Sort children in ascending z-order
    // Input: unsorted _children
    // Output: sorted _zOrderedChildren
    final void recomputeZOrderedChildren()
    {
        // Get a z-ordered list of childrens
        _zOrderedChildren.clearContents();
        foreach(child; getChildren())
        {
            Widget asWidget = cast(Widget) child;
            assert(asWidget !is null); // Widget children must be widgets only
            _zOrderedChildren.pushBack(asWidget);
        }

        // This is a stable sort, so the order of children with same z-order still counts.
        grailSort!Widget(_zOrderedChildren[],
                            (a, b) nothrow @nogc 
                            {
                                if (a.zOrder < b.zOrder) return 1;
                                else if (a.zOrder > b.zOrder) return -1;
                                else return 0;
                            });
    }
}



void square(ref Canvas canvas, float x, float y, float s1, float s2)
{
    canvas.beginPath();
    canvas.moveTo(x - s1, y - s1 );
    canvas.lineTo(x + s1, y - s1 );
    canvas.lineTo(x + s2, y - s2 );
    canvas.lineTo(x - s2, y - s2 );
    canvas.moveTo(x - s1, y + s1 );
    canvas.lineTo(x + s1, y + s1 );
    canvas.lineTo(x + s2, y + s2 );
    canvas.lineTo(x - s2, y + s2 );
    canvas.moveTo(x - s1, y - s1);
    canvas.lineTo(x - s1, y + s1);
    canvas.lineTo(x - s2, y + s2);
    canvas.lineTo(x - s2, y - s2);
    canvas.moveTo(x + s1, y - s1);
    canvas.lineTo(x + s1, y + s1);
    canvas.lineTo(x + s2, y + s2);
    canvas.lineTo(x + s2, y - s2);
    canvas.fill();
}

void fillLine(ref Canvas canvas, vec2f A, vec2f B, float lineWidth)
{
    float lw = lineWidth * 0.5f;
    vec2f BA = (B - A);
    if (BA.magnitude() < 1e-4f) return;
    BA.fastNormalize();
    vec2f C = A + vec2f(BA.y, -BA.x) * lw;
    vec2f D = A + vec2f(-BA.y, BA.x) * lw;
    vec2f E = B + vec2f(BA.y, -BA.x) * lw;
    vec2f F = B + vec2f(-BA.y, BA.x) * lw;
    canvas.beginPath();
    canvas.moveTo(C.x, C.y);
    canvas.lineTo(D.x, D.y);
    canvas.lineTo(F.x, F.y);
    canvas.lineTo(E.x, E.y);
    canvas.fill();
}
