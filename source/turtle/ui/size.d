module turtle.ui.size;

import std.math;

pure nothrow @nogc @safe:

struct Size
{
public:

    pure nothrow @nogc @safe:   

    /// Creates a Size with the given width and height.
    this(float width, float height)
    {
        _width = width;
        _height = height;
    }

    /// Creates a Size with the given height and an infinite width.
    static Size fromHeight(float height)
    {
        return Size(float.infinity, height);
    }

    /// Creates a square Size whose width and height are twice the given dimension.
    static Size fromRadius(float radius)
    {
        return Size(2 * radius, 2 * radius);
    }

    /// Creates a Size with the given width and an infinite height.
    static Size fromWidth(float width)
    {
        return Size(width, float.infinity);
    }

    /// Creates a square Size whose width and height are the given dimension.
    static Size square(float dimension)
    {
        return Size(dimension, dimension);
    }

    /// The aspect ratio of this size
    float aspectRatio()
    {
        if (height != 0.0)
            return width / height;
        if (width > 0.0)
            return float.infinity;
        if (width < 0.0)
            return -float.infinity;
        return 0.0;
    }

    /// A Size with the width and height swapped.
    Size flipped()
    {
        return Size(_height, _width);
    }

    /// The vertical extent of this size.
    float height()
    {
        return _height;
    }

    /// Whether this size encloses a non-zero area. Negative areas are considered empty.
    bool isEmpty()
    {
        return _width <= 0.0 || _height <= 0.0;
    }

    /// Whether both components are finite (neither infinite nor NaN).
    bool isFinite()
    {
        return std.math.isFinite(_width) && std.math.isFinite(_height);
    }

    /// Returns true if either component is float.infinity, and false if both are finite (or negative infinity, or NaN).
    bool isInfinite()
    {
        return _width >= float.infinity || _height >= float.infinity;
    }

    /// The greater of the magnitudes of the width and the height.
    float longestSide()
    {
        float w = abs(_width);
        float h = abs(_height);
        return w > h ? w : h;
    }

    /// The lesser of the magnitudes of the width and the height.
    float shortestSide()
    {
        float w = abs(_width);
        float h = abs(_height);
        return w < h ? w : h;
    }

    /// The horizontal extent of this size.
    float width()
    {
        return _width;
    }

    /// The offset to the center of the bottom edge of the rectangle described by the given offset 
    /// (which is interpreted as the top-left corner) and this size.
   /* Offset bottomCenter(Offset origin) → Offset
        
            bottomLeft(Offset origin) → Offset
            The offset to the intersection of the bottom and left edges of the rectangle described by the given offset (which is interpreted as the top-left corner) and this size. [...]
                bottomRight(Offset origin) → Offset
                The offset to the intersection of the bottom and right edges of the rectangle described by the given offset (which is interpreted as the top-left corner) and this size. [...]
                    center(Offset origin) → Offset
                    The offset to the point halfway between the left and right and the top and bottom edges of the rectangle described by the given offset (which is interpreted as the top-left corner) and this size. [...]
                        centerLeft(Offset origin) → Offset
                        The offset to the center of the left edge of the rectangle described by the given offset (which is interpreted as the top-left corner) and this size. [...]
                            centerRight(Offset origin) → Offset
                            The offset to the center of the right edge of the rectangle described by the given offset (which is interpreted as the top-left corner) and this size. [...]
*/

    Size extend(float marginOrPadding)
    {
        return Size(_width + marginOrPadding * 2, _height + marginOrPadding * 2);
    }

    bool bounded()
    {
        return std.math.isFinite(width) && std.math.isFinite(height);
    }

private:
    float _width;
    float _height;
}

Size minimumSize(Size a, Size b)
{
    return Size( (a.width >= b.width ? b.width : a.width), 
                 (a.height >= b.height ? b.height : a.height));
}

Size maximumSize(Size a, Size b)
{
    return Size( (a.width <= b.width ? b.width : a.width), 
                 (a.height <= b.height ? b.height : a.height));
}