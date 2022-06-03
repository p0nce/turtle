module turtle.ui.container;

import dplug.graphics;
import turtle.ui.widget;

/// Use a Container when you want to add padding or background color.
class Container : Widget
{
public:
    
    this(IUIContext context)
    {
        super(context);
    }

    void padding(int pixels)
    {
        _padding = pixels;
    }   

    void color(RGBA newColor)
    {
        _bg = newColor;
    }

    override void rawDraw(ImageRef!RGBA raw)
    {
        if (_bg.a != 0)
        {
            raw.aaFillRect(0, 0, getWidth, getHeight, _bg);
        }
        // default = do nothing
    }

    override Size promptSize(BoxConstraints constraints)
    {
        if (hasNoChild())
        {
            /// "Containers with no children try to be as big as possible unless the incoming constraints are unbounded,"
            /// "in which case they try to be as small as possible.
            float w = constraints.hasBoundedWidth()  ? constraints.minWidth  : constraints.maxWidth;
            float h = constraints.hasBoundedHeight() ? constraints.minHeight : constraints.maxHeight;
            return Size(w, h);
        }
        else if (hasOneChild())
        {
            // "Containers with children size themselves to their children."
            // "The width, height, and constraints arguments to the constructor override this."

            // Also in another place:
            // "Otherwise, the widget has a child but no height, no width, no constraints," 
            // "and no alignment, and the Container passes the constraints from the parent "
            // "to the child and sizes itself to match the child."


            float paddingHorzSize = _padding + _padding;
            float paddingVertSize = _padding + _padding;

            // make constraint for child, finds what size it choose to be.
            float minWidth = constraints.minWidth - paddingHorzSize;
            float minHeight = constraints.minHeight - paddingVertSize;
            float maxWidth = constraints.maxWidth - paddingHorzSize;
            float maxHeight = constraints.maxHeight - paddingVertSize;
            if (minWidth < 0) minWidth = 0;
            if (minHeight < 0) minHeight = 0;
            if (maxWidth < 0) maxWidth = 0;
            if (maxHeight < 0) maxHeight = 0;

            BoxConstraints childConstraint = BoxConstraints(minWidth, maxWidth, minHeight, maxHeight);

            // TODO: Padding is an optional thing, so technically the constraints are loosened by presence of padding.
            Size childSize = firstChild.promptSize( constraints );
            return childSize;
        }
        else
            assert(false);
    }

    override void reflow()
    {
        if (hasNoChild())
            return;

        assert(hasOneChild());

        float W = getWidth();
        float H = getHeight();

        float paddingHorzSize = _padding + _padding;
        float paddingVertSize = _padding + _padding;

        // make constraint for child, finds what size it choose to be.
        float minWidth = 0;
        float minHeight = 0;
        float maxWidth = W - paddingHorzSize;
        float maxHeight = H - paddingVertSize;
        if (maxWidth < 0) maxWidth = 0;
        if (maxHeight < 0) maxHeight = 0;

        Size childSize = firstChild.promptSize(BoxConstraints(minWidth, maxWidth, minHeight, maxHeight));

        // "Container tries, in order: to honor alignment, to size itself to the child, to honor the width, height, "
        // "and constraints, to expand to fit the parent, to be as small as possible."

        float roomHorz = W - childSize.width;
        float roomVert = H - childSize.height;        

        // Compute actually used padding
        float actualPadLeft = _padding;
        if (roomHorz < 0) actualPadLeft = 0;
        else if (roomHorz < 2 * _padding) actualPadLeft = roomHorz * 0.5f;
        float actualPadTop = _padding;
        if (roomVert < 0) actualPadTop = 0;
        else if (roomVert < 2 * _padding) actualPadTop = roomVert * 0.5f;
        
        firstChild.setPosition(actualPadLeft, actualPadTop, childSize);
    }

   /* // TODO: manage case where padding cannot actually be applied
    static BoxConstraints withPadding(BoxConstraints sc, float padding)
    {       
        
        float minWidth = sc.minWidth - 2*padding;
        if (minWidth < 0)
            minWidth  = 0;
        float minHeight = sc.minHeight - 2*padding;
        if (minHeight < 0)
            minHeight  = 0;
        float maxWidth = sc.maxWidth - 2*padding;
        float maxHeight = sc.maxHeight - 2*padding;

        BoxConstraints r = BoxConstraints(minWidth, maxWidth, minHeight, maxHeight);
        assert(r.isNormalized());
        return r;
    }
*/

private:
    RGBA _bg = RGBA(0, 0, 0, 0); // transparent
    int _padding = 0;
}

Widget withPadding(Widget widget, int padding)
{
    Container cont = new Container(widget.context());
    cont.addChild(widget);
    cont.padding = padding;    
    return cont;
}


