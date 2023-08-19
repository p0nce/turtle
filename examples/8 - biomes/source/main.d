import std.random;

//import dplug.core;
import dplug.graphics;
import turtle;
import gamut;
import fast_noise;


// Based upon http://www.jgallant.com/procedurally-generating-wrapping-world-maps-in-unity-csharp-part-1/#noisegeneration

int main(string[] args)
{
    runGame(new RawRenderExample);
    return 0;
}

class RawRenderExample : TurtleGame
{
    override void load()
    {
        setBackgroundColor( color("black") );
        
    }

    enum GRID_SUBSAMPLING = 2;

    override void resized(float width, float height)
    {
        _width = cast(int)(width);
        _height = cast(int)(height);
        generateNewMap(_width, _height);
    }

    double zoom = 1.0;
    double offsetX = 0;
    double offsetY = 0;

    override void update(double dt)
    {
        enum MOVEMENT_SPEED = 20;

        if (keyboard.isDown("escape")) exitGame;
        if (keyboard.isDown("left"))
        {
            offsetX = offsetX - dt * MOVEMENT_SPEED * zoom;
            generateNewMap(_width, _height);
        }
        if (keyboard.isDown("right"))
        {
            offsetX = offsetX + dt * MOVEMENT_SPEED * zoom;
            generateNewMap(_width, _height);
        }
        if (keyboard.isDown("up"))
        {
            offsetY = offsetY - dt * MOVEMENT_SPEED * zoom;
            generateNewMap(_width, _height);
        }
        if (keyboard.isDown("down"))
        {
            offsetY = offsetY + dt * MOVEMENT_SPEED * zoom;
            generateNewMap(_width, _height);
        }
    }

    override void mouseWheel(float wheelX, float wheelY)
    {
        if (wheelY > 0)
            zoom = zoom * 1.1;
        if (wheelY < 0)
            zoom = zoom / 1.1;
        generateNewMap(_width, _height);
    }

    enum float MIN_DEGREES = -10;
    enum float MAX_DEGREES = 32;

    enum float MIN_ALTITUDE = -600; // in meters
    enum float MAX_ALTITUDE = 1200; // in meters
    enum float SEA_LEVEL = 0;

    void generateNewMap(int width, int height, bool warp = false)
    {
        uint seed = 1; // keep same seed so that we can zoom in

        float elevationFreq = 0.005;
        float heatFreq      = 0.001;
        float moistureFreq  = 0.001;

        elevationMap.create(width, height, PixelType.lf32);
        elevationMap.randomFloatTexture(seed, MIN_ALTITUDE, MAX_ALTITUDE, 
                                        elevationFreq, offsetX, offsetY, 1.0 / zoom);

        heatMap.create(width, height, PixelType.lf32);
   
        heatMap.randomFloatTexture(seed+1, MIN_DEGREES, MAX_DEGREES, 
                                   heatFreq, offsetX, offsetY, 1.0 / zoom);

        moistureMap.create(width, height, PixelType.lf32);
        moistureMap.randomFloatTexture(seed+2, 0, 400.0f,  // precipitation by cm
                                       moistureFreq, offsetX, offsetY, 1.0 / zoom);

        biomeMap.create(width, height, PixelType.l8);

        // Adjust precipitation by heat to better fit the Whittaker classification, 
        // at -10 there is no rain in the graph.        
        for (int y = 0; y < height; ++y)
        {
            float* heatScan      = cast(float*) heatMap.scanptr(y);
            float* elevationScan = cast(float*) elevationMap.scanptr(y);
            float* moistureScan  = cast(float*) moistureMap.scanptr(y);

            for (int x = 0; x < width; ++x)
            {
                float heat = heatScan[x];
                float moisture = moistureScan[x];
                float elevation = elevationScan[x]; // 1.0 = high, SEA_LEVEL = sea level

                // Also adjust heat by elevation.
                // Every 1000m, loose 10 Celsius degrees
                float aboveGroundMeters = (elevation - SEA_LEVEL);
                if (aboveGroundMeters < 0)
                    aboveGroundMeters = 0;
                heat -= 10 * (aboveGroundMeters / 1000);

                float amp = (heat - MIN_DEGREES) / (MAX_DEGREES - MIN_DEGREES);
                float moistureScaled = moisture * amp;
                moistureScan[x] = moistureScaled;
            }
        }


        // Assign biome type to each pixel
        for (int y = 0; y < height; ++y)
        {
            float* elevationScan = cast(float*) elevationMap.scanptr(y);
            float* heatScan      = cast(float*) heatMap.scanptr(y);
            float* moistureScan  = cast(float*) moistureMap.scanptr(y);
            BiomeType* biomeScan = cast(BiomeType*) biomeMap.scanptr(y);

            for (int x = 0; x < width; ++x)
            {
                float heat = heatScan[x];
                float moisture = moistureScan[x];
                float elevation = elevationScan[x];
                BiomeType biome;

                if (elevation < SEA_LEVEL - 120)
                    biome = BiomeType.DeepOcean;
                else if (elevation < SEA_LEVEL - 30)
                    biome = BiomeType.Ocean;
                else if (elevation < SEA_LEVEL)
                    biome = BiomeType.ShallowSea;
                else if (heat > 20)
                {
                    if (moisture > 250) biome = BiomeType.TropicalRainforest;
                    else if (moisture > 75) biome = BiomeType.SeasonalForest; // not exactly like image
                    else biome = BiomeType.Desert; // not exactly like image
                }
                else if (heat < 0)
                {
                    biome = BiomeType.Ice;
                }
                else if (moisture < 40)
                    biome = BiomeType.Desert; 
                else if (heat < 7)
                {
                    biome = BiomeType.Tundra; 
                }
                else
                {
                    if (moisture > 200) biome = BiomeType.TemperateRainforest;
                    else if (moisture > 100) biome = BiomeType.SeasonalForest;
                    else if (moisture > 50) biome = BiomeType.Woodland;
                }
                biomeScan[x] = biome;
            }
        }

        renderedMap.create(width, height, PixelType.rgba8);

        for (int y = 0; y < height; ++y)
        {
            float* elevationScan = cast(float*) elevationMap.scanptr(y);
            ubyte* renderScan = cast(ubyte*) renderedMap.scanptr(y);
            BiomeType* biomeScan = cast(BiomeType*) biomeMap.scanptr(y);

            for (int x = 0; x < width; ++x)
            {
                RGBA color = biomeColor(biomeScan[x]); 

                renderScan[4*x+0] = color.r;
                renderScan[4*x+1] = color.g;
                renderScan[4*x+2] = color.b;
                renderScan[4*x+3] = color.a;
            }
        }

    }

    override void draw()
    {
        ImageRef!RGBA framebuf = framebuffer();
        int W = framebuf.w;
        int H = framebuf.h;

        assert(W == renderedMap.width);
        assert(H == renderedMap.height);

        // Just blit pixels
        for (int y = 0; y < H; ++y)
        {
            ubyte* frameScan = cast(ubyte*)(framebuf.scanline(y).ptr);
            ubyte* renderScan = cast(ubyte*)(renderedMap.scanptr(y));
            frameScan[0..4*W] = renderScan[0..4*W];
        }
    }

    int _width;
    int _height;

    Image elevationMap;
    Image renderedMap;
    Image heatMap;
    Image moistureMap;
    Image biomeMap; // contains BiomeType values
}

enum BiomeType : byte
{
    DeepOcean,
    Ocean,
    ShallowSea,
	Desert,
	Savanna,
	TropicalRainforest,
	Grassland,
	Woodland,
	SeasonalForest,
	TemperateRainforest,
	BorealForest,
	Tundra,
	Ice
}


void randomFloatTexture(ref Image image_l8f, 
                        uint seed,
                        float min, 
                        float max, 
                        double frequency,
                        double offsetX, // center of camera X and Y
                        double offsetY,
                        double zoom)
{
    FNLState noiseState = fnlCreateState();
    noiseState.seed = seed;       
    noiseState.fractal_type = FNLFractalType.FNL_FRACTAL_FBM;
    noiseState.frequency = frequency;

    int octaves = cast(int)(5.0f - log2(zoom));
    if (octaves < 6) octaves = 6;
    if (octaves > 12) octaves = 12;
    noiseState.octaves = octaves;

    noiseState.lacunarity = 2.2;

    double halfWidth = image_l8f.width * 0.5;
    double halfHeight = image_l8f.height * 0.5;

    for (int y = 0; y < image_l8f.height; ++y)
    {
        float* scan = cast(float*) image_l8f.scanptr(y);
        for (int x = 0; x < image_l8f.width; ++x)
        {
            double nx = offsetX + zoom*(x - halfWidth);
            double ny = offsetY + zoom*(y - halfHeight);
            fnlDomainWarp2D(&noiseState, &nx, &ny);
            float noise = 0.5f + 0.5f * fnlGetNoise2D(&noiseState, nx, ny);
            scan[x] = min + noise * (max - min);
        }
    }
}

RGBA biomeColor(BiomeType biome)
{
    final switch (biome) with (BiomeType)
    {
        case DeepOcean: return RGBA(56, 61, 82, 255);
        case Ocean: return RGBA(106, 131, 162, 255);
        case ShallowSea: return RGBA(200, 200, 148, 255);
        case Desert: return RGBA(238, 218, 130, 255);
        case Savanna: return RGBA(177, 209, 110, 255);
        case TropicalRainforest: return RGBA(66, 123, 25, 255);
        case Grassland: return RGBA(164, 225, 99, 255);
        case Woodland: return RGBA(139, 175, 90, 255);
        case SeasonalForest: return RGBA(73, 100, 35, 255);
        case TemperateRainforest:return RGBA(29, 73, 40, 255);
        case BorealForest: return RGBA(95, 115, 62, 255);
        case Tundra:return RGBA(96, 131, 112, 255);
        case Ice: return RGBA(255, 255, 255, 255);
    }
}
