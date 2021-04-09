module tinygame.vector2;

version(none):

import std.math;

/// 2-element structure that can be used to represent positions in 2D space or any other pair of 
/// numeric values.
struct Vector2
{
    union 
    {
		float x = 0;
		float width;
	};
	union 
    {
		float y = 0;
		float height;
	};

    /// Constructs a new `Vector2` from the given `x` and `y`.
    this(float x, float y)
    {
        this.x = x;
        this.x = y;
    }

    /// Returns a new vector with all components in absolute values (i.e. positive).
    Vector2 abs()
    {
        return Vector2(std.math.abs(x), std.math.abs(y));
    }

    /// Returns this vector's angle with respect to the positive X axis, or (1, 0) vector, in 
    /// radians.
    /// For example, `Vector2.RIGHT.angle()` will return zero, 
    ///              `Vector2.DOWN.angle()` will return `PI / 2`
    ///          and `Vector2(1, -1).angle()` will return `-PI / 4`
    float angle()
    {
        return atan2(y, x);
    }

    /// Returns the aspect ratio of this vector, the ratio of x to y.
    /// Returns: `x` / `y`.
    float aspect_ratio()
    {
        return x / y;
    }
        
}