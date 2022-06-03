module turtle.ui.boxconstraints;

import std.math;
import turtle.ui.size;

pure nothrow @nogc @safe:

struct BoxConstraints
{
    pure nothrow @nogc @safe:
    // Constructors

    /// Creates box constraints with the given constraints.
    this(float minWidth, float maxWidth, float minHeight, float maxHeight)
    {
        _minWidth = minWidth;
        _maxWidth = maxWidth;
        _minHeight = minHeight;
        _maxHeight = maxHeight;
    }

    /// Creates box constraints that forbid sizes larger than the given size.        
    static BoxConstraints loose(Size size)
    {
        return BoxConstraints(0, size.width, 0, size.height);
    }

    /// Creates box constraints that is respected only by the given size.
    static BoxConstraints tight(Size size)
    {
        return BoxConstraints(size.width, size.width, size.height, size.height);
    }

    /// Creates box constraints that require the given width or height, except if they are infinite.
    static BoxConstraints tightForFinite(float width, float height)
    {
        float minWidth  = (width  >= float.infinity) ? 0 : width;
        float maxWidth  = (width  >= float.infinity) ? float.infinity : width;
        float minHeight = (height >= float.infinity) ? 0 : height;
        float maxHeight = (height >= float.infinity) ? float.infinity : height;
        return BoxConstraints(minWidth, maxWidth, minHeight, maxHeight);
    }


/*
    Size clampSize(Size inputSize)
    {
        assert(isValid());
        Size r = inputSize;
        if (r.width < minWidth)
            r.width = minWidth;
        if (r.height < minHeight)
            r.height = minHeight;
        if (r.width > maxWidth)
            r.width = maxWidth;
        if (r.height > maxHeight)
            r.height = maxHeight;
        return r;
    }

    Size minimumPossibleSize()
    {
        assert(isValid());
        return Size(minWidth, minHeight);
    }

    Size maximumPossibleSize()
    {
        assert(isValid());
        return Size(maxWidth, maxHeight);
    }
*/

    bool hasBoundedWidth()
    {
        return isFinite(maxWidth);
    }

    bool hasBoundedHeight()
    {
        return isFinite(maxHeight);
    }

   
    /// Returns whether the object's constraints are normalized. 
    /// Constraints are normalized if the minimums are less than or equal to the corresponding maximums.
    /// For example, a `BoxConstraints` object with a `minWidth` of 100.0 and a `maxWidth` of 90.0 is not normalized.
    /// Most of the APIs on BoxConstraints expect the constraints to be normalized and have undefined behavior when they are not.
    bool isNormalized()
    {
        return (_minWidth >= 0)
            &&(_minHeight >= 0)
            &&(_maxWidth >= _minWidth)
            &&(_maxHeight >= _minHeight);
    }

    /// The maximum height that satisfies the constraints.
    float maxHeight() { return _maxHeight; }

    /// The maximum width that satisfies the constraints.
    float maxWidth() { return _maxWidth; }

    /// The minimum height that satisfies the constraints.
    float minHeight() { return _minHeight; }

    /// The minimum width that satisfies the constraints.
    float minWidth() { return _minWidth; }

    /// Returns the size that both satisfies the constraints and is as close as possible to the given size.
    Size constrain(Size size)
    {
       return Size(constrainWidth(size.width), constrainHeight(size.height));
    }   

    /// Returns the width that both satisfies the constraints and is as close as possible to the given width.
    float constrainWidth(float width = float.infinity)
    {
        assert(isNormalized);
        if (width < _minWidth) width = _minWidth;
        if (width > _maxWidth) width = _maxWidth;
        return width;
    }      

    /// Returns the height that both satisfies the constraints and is as close as possible to the given height.
    float constrainHeight(float height = float.infinity)
    {
        assert(isNormalized);
        if (height < _minHeight) height = _minHeight;
        if (height > _maxHeight) height = _maxHeight;
        return height;
    }


    /// Whether the given size satisfies the constraints.
    bool isSatisfiedBy(Size size)
    {
        assert(isNormalized());
        return size.width >= minWidth && size.width <= maxWidth
            && size.height >= minHeight && size.height <= maxHeight;
    }

private:
    float _minWidth;
    float _minHeight;
    float _maxWidth;
    float _maxHeight;
}