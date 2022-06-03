module turtle.ui.rowcolumn;

import turtle.ui.widget;

enum MainAxis
{
    /// Flex widget is a column.
    vert,

    /// Flex widget is a row.
    horz
}

/// The mainAxisSize property determines how much space a Row and Column can occupy on their main axes.
enum MainAxisSize
{
    /// Row and Column only occupy enough space on their main axes for their children. 
    /// Their children are laid out without extra space and at the middle of their main axes.
    min,

    // Row and Column occupy all of the space on their main axes. If the combined width of their 
    // children is less than the total space on their main axes, their children are laid out 
    // with extra space.
    max
}

enum CrossAxisAlignment
{  
    /// Positions children near the start of the cross axis. (Top for Row, Left for Column)
    start,

    /// Positions children near the end of the cross axis. (Bottom for Row, Right for Column)
    end,

    /// Positions children at the middle of the cross axis. (Middle for Row, Center for Column)
    center,

    /// Stretches children across the cross axis. (Top-to-bottom for Row, left-to-right for Column)
    stretch        
}

/// Layout a list of child widgets in the vertical direction.
class Column : ColumnOrRow
{
    this(IUIContext context)
    {
        super(context, MainAxis.vert);
    }
}

/// Layout a list of child widgets in the horizontal direction.
class Row : ColumnOrRow
{
    this(IUIContext context)
    {
        super(context, MainAxis.horz);
    }
}

class ColumnOrRow : Widget
{
    this(IUIContext context, MainAxis mainAxis)
    {
        _mainAxis = mainAxis;
        super(context);
    }

    void setCrossAxisAlignment(CrossAxisAlignment crossAlign)
    {
        crossAxisAlignment = crossAlign;
    }    
    
    void setMainAxisSize(MainAxisSize mainAxisSize)
    {
        _mainAxisSize = mainAxisSize;
    }

    override Size promptSize(BoxConstraints constraints)
    {
        int N = numChildren;
        Size res;

        Size[] s = new Size[N];

        float maxChildCross = 0;
        float sumOfChildMain = 0;
        for(int n = 0; n < N; ++n)
        {
            // Find size of childrens with unlimited height constraint
            // (which signals to children they should take as little room as possible...)
            BoxConstraints c;
            if (_mainAxis == MainAxis.vert)
            {
                float minWidth = (crossAxisAlignment == CrossAxisAlignment.stretch) ? constraints.maxWidth : constraints.minWidth;
                float maxWidth = constraints.maxWidth;
                float minHeight = 0;        
                float maxHeight = float.infinity;
                c = BoxConstraints(minWidth, maxWidth, minHeight, maxHeight);
            }
            else
            {
                float minHeight = (crossAxisAlignment == CrossAxisAlignment.stretch) ? constraints.maxHeight : constraints.minHeight;
                float maxHeight = constraints.maxHeight;
                float minWidth = 0;        
                float maxWidth = float.infinity;
                c = BoxConstraints(minWidth, maxWidth, minHeight, maxHeight);
            }

            assert(c.isNormalized());

            s[n] = child(n).promptSize(c);
            assert(s[n].bounded);
            float mainDim = (_mainAxis == MainAxis.vert) ?  s[n].height : s[n].width;
            float crossDim = (_mainAxis == MainAxis.vert) ?  s[n].width : s[n].height;
            if (crossDim > maxChildCross)
                maxChildCross = crossDim;   
            sumOfChildMain += mainDim;
        }         

        float reswidth, resheight;
        if (_mainAxis == MainAxis.vert)
        {
            reswidth = maxChildCross;
            resheight = (_mainAxisSize.min == MainAxisSize.min) ? sumOfChildMain : constraints.maxHeight;
        }
        else
        {
            reswidth = (_mainAxisSize.min == MainAxisSize.min) ? sumOfChildMain : constraints.maxWidth;
            resheight = maxChildCross;
        }

        return constraints.constrain( Size(reswidth, resheight) );
    }

    override void reflow()
    {
        box2f R = getPositionRect();
        int N = numChildren;
        Size[] s = new Size[N];

        float maxChildCross = 0;
        float sumOfChildMain = 0;

        float minWidth = 0;
        float minHeight = 0;
        float maxWidth = R.width;
        float maxHeight = R.height;

        for (int n = 0; n < N; ++n)
        {
            // Find size of childrens with actual size constraints
            if (_mainAxis == MainAxis.vert)
            {
                minWidth = (crossAxisAlignment == CrossAxisAlignment.stretch) ? maxWidth : minWidth;
            }
            else
            {
                minHeight = (crossAxisAlignment == CrossAxisAlignment.stretch) ? maxHeight : minHeight;
            }

            s[n] = child(n).promptSize( BoxConstraints(minWidth, maxWidth, minHeight, maxHeight ));
            assert(s[n].bounded);
            float mainDim = (_mainAxis == MainAxis.vert) ?  s[n].height : s[n].width;
            float crossDim = (_mainAxis == MainAxis.vert) ?  s[n].width : s[n].height;

            if (crossDim > maxChildCross)
                maxChildCross = crossDim;   
            sumOfChildMain += mainDim;


            if (_mainAxis == MainAxis.vert)
                maxHeight -= mainDim; // TODO: introduce direction
            else
                maxWidth -= mainDim; // TODO: introduce direction
        }

        // Sets children positions inside parent

        float mainCoord = 0;

        for (int n = 0; n < N; ++n)
        {
            // TODO implement alignement along Main axis?

            float mainDim = (_mainAxis == MainAxis.vert) ?  s[n].height : s[n].width;
            float crossDim = (_mainAxis == MainAxis.vert) ?  s[n].width : s[n].height;

            float parentCross = (_mainAxis == MainAxis.vert) ? R.width : R.height;

            float crossCoord = 0;

            final switch(crossAxisAlignment) with (CrossAxisAlignment)
            {
                case start:
                case stretch:
                    crossCoord = 0; break;
                case end:
                    crossCoord = parentCross - crossDim; break;
                case center:
                    crossCoord = (parentCross - crossDim) * 0.5f; break;
            }

            float x = (_mainAxis == MainAxis.vert) ? crossCoord : mainCoord;
            float y = (_mainAxis == MainAxis.vert) ? mainCoord : crossCoord;
            child(n).setPosition(x, y, s[n].width, s[n].height);
            mainCoord += mainDim;
        }
    }

private:
    MainAxis _mainAxis; // MainAxis.vert for Column, MainAxis.horz for Row.
    MainAxisSize _mainAxisSize = MainAxisSize.min;
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center;
}

//class If given a child, this widget forces it to have a specific width and/or height. These values will be ignored if this widget's parent does not permit them.