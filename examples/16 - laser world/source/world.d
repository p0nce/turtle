module world;

import std.random;

import dplug.graphics;
import turtle;
import gamut;
import fast_noise;


enum BiomeType : byte
{
    Empty,
    DeepOcean,
    SomewhatDeepOcean,
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

string biomeGraphics(BiomeType bt)
{
    final switch(bt) with (BiomeType)
    {
        case Empty: return "<on_black> </>";
        case DeepOcean: return "<black><on_blue>~</></>";
        case SomewhatDeepOcean: return "<grey><on_blue>~</></>";
        case Ocean: return "<lgrey><on_lblue>~</></>";
        case ShallowSea: return "<white><on_lblue>~</></>";
        case Desert: return "<on_yellow> </on_yellow>";
        case Savanna: return "~";
        case TropicalRainforest: return "~";
        case Grassland: return "<on_black><green>\"</></>";
        case Woodland: return "<on_orange>o</on_orange>";
        case SeasonalForest: return "<on_green><lgrey>o</></>";
        case TemperateRainforest: return "<on_green><grey>o</></>";
        case BorealForest: return "~";
        case Tundra: return "<lcyan>\"</>";
        case Ice: return "<on_lblue> </>";
    }
}

// Based upon http://www.jgallant.com/procedurally-generating-wrapping-world-maps-in-unity-csharp-part-1/#noisegeneration
class World
{
    this(uint seed, int width, int height )
    {
        _width = cast(int)(width);
        _height = cast(int)(height);
        generateNewMap(seed, _width, _height);
    }

    BiomeType biomeAt(int x, int y)
    {
        if (!contains(x, y))
            return BiomeType.Empty;
        return (cast(BiomeType*) biomeMap.scanptr(y))[x];
    }

    bool contains(int x, int y)
    {
        return (cast(uint)x < width) && (cast(uint)y < height);
    }

    int width(){ return _width; }
    int height(){return _height; }

private:


     double zoom = 1.0;
    double offsetX = 0;
    double offsetY = 0;
    enum float MIN_DEGREES = -10;
    enum float MAX_DEGREES = 32;

    enum float MIN_ALTITUDE = -1100; // in meters
    enum float MAX_ALTITUDE = 1100; // in meters
    enum float SEA_LEVEL = 0;
    enum float MAX_MOISTURE = 400.0f;

    void generateNewMap(uint seed, int width, int height, bool warp = false)
    {
        float elevationFreq = 0.002;
        float heatFreq      = 0.0012;
        float moistureFreq  = 0.0015;

        elevationMap.create(width, height, PixelType.lf32);
        elevationMap.randomFloatTexture(seed, FNLNoiseType.FNL_NOISE_PERLIN,
                                        FNLFractalType.FNL_FRACTAL_FBM,
                                        10.0f,
                                        MAX_ALTITUDE, MIN_ALTITUDE,
                                        elevationFreq, offsetX, offsetY, 1.0 / zoom);

        heatMap.create(width, height, PixelType.lf32);
   
        heatMap.randomFloatTexture(seed+1, FNLNoiseType.FNL_NOISE_OPENSIMPLEX2,
                                   FNLFractalType.FNL_FRACTAL_FBM,
                                   4.0f,
                                   MIN_DEGREES, MAX_DEGREES, 
                                   heatFreq, offsetX, offsetY, 1.0 / zoom);

        moistureMap.create(width, height, PixelType.lf32);
        moistureMap.randomFloatTexture(seed+2, FNLNoiseType.FNL_NOISE_OPENSIMPLEX2,
                                       FNLFractalType.FNL_FRACTAL_FBM,
                                       4.0f,
                                       0, MAX_MOISTURE,  // precipitation by cm
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

                // Apply pow on elevation
                // if (elevation > 0) elevation = MAX_ALTITUDE * ((elevation/MAX_ALTITUDE) ^^ 0.5);
                // elevationScan[x] = elevation;

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
                else if (elevation < SEA_LEVEL - 75)
                    biome = BiomeType.SomewhatDeepOcean;
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
                else if (heat < 7)
                {
                    biome = BiomeType.BorealForest; 
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
    }

    int _width;
    int _height;

    Image elevationMap;
    Image heatMap;
    Image moistureMap;
    Image biomeMap;
}



void randomFloatTexture(ref Image image_l8f, 
                        uint seed,
                        FNLNoiseType noiseType,
                        FNLFractalType fractalType,
                        float baseOctave,
                        float min, 
                        float max, 
                        double frequency,
                        double offsetX, // center of camera X and Y
                        double offsetY,
                        double zoom)
{
    FNLState noiseState = fnlCreateState();
    noiseState.seed = seed;      
    noiseState.noise_type = noiseType;
    noiseState.fractal_type = fractalType;
    noiseState.frequency = frequency;

    int octaves = cast(int)(baseOctave + log2(zoom));
    if (octaves < 6) octaves = 6;
    if (octaves > 12) octaves = 12;
    noiseState.octaves = octaves;
    noiseState.lacunarity = 2.0;

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
