module texture;

public import gamut;

class TextureManager
{
    this(int n)
    {
        _textures.length = n;        
    }

    void add(const(char)[] path, int w, int h)
    {
        _textures[_count].loadFromFile(path);
        if (_textures[_count].isError)
            throw new Exception("Couldn't load image");
        _textures[_count].convertTo(PixelType.rgba8);
        _count++;
    }

    Image* get(int i)
    {
        return &_textures[i];
    }

    int count()
    {
        return _count;
    }    

private:
    Image[] _textures;
    int _count;
}
