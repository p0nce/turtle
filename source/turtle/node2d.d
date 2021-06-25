module turtle.node2d;

import dplug.math.vector;
import dplug.canvas;


class Node
{
public:

    this()
    {
    }

    ~this()
    {
        foreach(child; _children)
            destroy(child);
    }

    /// Returns the parent node of the current node, or `null` if the node lacks a parent.
    Node getParent()
    {
        return _parent;
    }

    /// Add child. Return parent for chaining.
    Node addChild(Node node)
    {
        node._parent = this;
        _children ~= node;
        return this;
    }

    /// Removes a child node. The node is NOT deleted and must be deleted manually.
    void removeChild(Node node)
    {
        size_t i = 0;
        while (i < _children.length)
        {
            if (node is _children[i])
            {
                _children[i] = _children[$-1];
                _children.length = _children.length - 1;
                return;
            }
            else
                ++i;
        }
    }

    void update(double deltaTime)
    {
    }

    Node[] getChildren()
    {
        return _children;
    }

    /// Draw Node and its children on this canvas.
    /// This call their `draw()` methods recursively, using each `Node2D` transform.
    /// Usually you would take the one returned by the `Game.canvas()` call.
    void drawOnCanvas(Canvas* canvas)
    {
        Node2D this2D = cast(Node2D)this;
        if (this2D) 
        {
            canvas.save;
            canvas.translate(this2D._position);
            canvas.rotate(this2D._rotation);
            canvas.scale(this2D._scale);


            this2D.draw(canvas);
            foreach (child; _children)
                child.drawOnCanvas(canvas);
            canvas.restore;
        }
        else
        {
            foreach (child; _children)
                child.drawOnCanvas(canvas);
        }

    }

package:  

    final void doUpdate(double deltaTime)
    {
        update(deltaTime);
        foreach (child; _children)
            child.doUpdate(deltaTime);
    }

private:
    Node _parent;
    Node[] _children;
}

/// A 2D game object, with a transform (position, rotation, and scale).
class Node2D : Node
{
public:

    /// Override this to draw something.
    /// The canvas should be transformed by this node's position, scale, and rotation.
    void draw(Canvas* canvas)
    {
        // by default: do nothing
    }

    final vec2f position()
    {
        return _position;
    }

    final void position(vec2f pos)
    {
        _position = pos;
    }

    /// Sets the node's scale. 
    final vec2f scale()
    {
        return _scale;
    }

    final void scale(vec2f s)
    {
        _scale = s;
    }

    /// Get rotation in radians, relative to the node's parent.
    final float rotation()
    {
        return _rotation;
    }

    /// Set rotation in radians, relative to the node's parent.
    final void rotation(float angle)
    {
        _rotation = angle;
    }

    /// Translates the node by the given offset in local coordinates.
    void translate(vec2f offset)
    {
        _position += offset;
    }
      

private:
    vec2f _position = vec2f(0, 0);
    vec2f _scale = vec2f(1, 1);
    float _rotation = 0.0f;
}