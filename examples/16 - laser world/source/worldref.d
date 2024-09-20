module worldref;

import std.random;
import std.math: log2;
import biomes;
import gamut;
import fast_noise;

// Return biome data.
// Based upon http://www.jgallant.com/procedurally-generating-wrapping-world-maps-in-unity-csharp-part-1/#noisegeneration
class WorldReference
{
    this(uint seed)
    {
        this.seed = seed;
    }

private:

    uint seed;
    double zoom = 1.0;
    double offsetX = 0;
    double offsetY = 0;
    enum float MIN_DEGREES = -10;
    enum float MAX_DEGREES = 32;

    enum float MIN_ALTITUDE = -1100; // in meters
    enum float MAX_ALTITUDE = 1100; // in meters
    enum float SEA_LEVEL = 0;
    enum float MAX_MOISTURE = 400.0f;

    // to generate only one map, do not change zoom factor
    public void generateBiomeData(int x,
                           int y,
                           int width, 
                           int height,
                           BiomeType[] output) // width x height data points
    {
        float elevationFreq = 0.002;
        float heatFreq      = 0.0012;
        float moistureFreq  = 0.0015;
        bool warp = false;

        // Note: it is probably we'll have at some point inaccuracies
        // because texture center is generated with that early conversion to float
        // but this should be rare
        assert(width == height);
        double offsetX = (x+width*0.5) / zoom; 
        double offsetY = (y+height*0.5) / zoom;

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
        for (int j = 0; j < height; ++j)
        {
            float* heatScan      = cast(float*) heatMap.scanptr(j);
            float* elevationScan = cast(float*) elevationMap.scanptr(j);
            float* moistureScan  = cast(float*) moistureMap.scanptr(j);

            for (int i = 0; i < width; ++i)
            {
                float heat = heatScan[i];
                float moisture = moistureScan[i];
                float elevation = elevationScan[i]; // 1.0 = high, SEA_LEVEL = sea level

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
                moistureScan[i] = moistureScaled;
            }
        }

        // Assign biome type to each pixel
        for (int j = 0; j < height; ++j)
        {
            float* elevationScan = cast(float*) elevationMap.scanptr(j);
            float* heatScan      = cast(float*) heatMap.scanptr(j);
            float* moistureScan  = cast(float*) moistureMap.scanptr(j);

            for (int i = 0; i < width; ++i)
            {
                float heat = heatScan[i];
                float moisture = moistureScan[i];
                float elevation = elevationScan[i];
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
                output[j*width+i] = biome;
            }
        }
    }

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
