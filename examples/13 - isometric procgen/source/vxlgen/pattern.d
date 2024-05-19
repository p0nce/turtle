module vxlgen.pattern;

import std.math;
import vxlgen.randutils;
import dplug.math.vector;

enum Pattern
{
    ONLY_ONE,
    BORDER,
    TILES_1X1,
    TILES_2X2,
    TILES_4X4,
    TILES_ZEBRA,
    TILES_L,
    TILES_2x2_1x1,
    CROSS,
    HOLES,
}

struct PatternEx
{
    Pattern pattern;
    bool swapIJ;
    bool swapColors;
    float noiseAmount;
}

vec3f patternColor(ref Random rng, PatternEx pattern, int i, int j, vec3f colorLight, vec3f colorDark)
{
    static vec3f subColor(int i, int j, Pattern pattern, vec3f colorLight, vec3f colorDark)
    {
        final switch (pattern)
        {
            case Pattern.ONLY_ONE:
                {
                    return colorLight;
                }

            case Pattern.BORDER:
                {
                    bool limit = (i % 4 == 0) || (j % 4 == 0);
                    return limit ? colorLight : colorDark;
                }

            case Pattern.TILES_1X1:
                return  (i ^ j) & 1 ? colorLight : colorDark;

            case Pattern.TILES_2X2:
                return  ((i/2) ^ (j/2)) & 1 ? colorDark : colorLight;

            case Pattern.TILES_4X4:
                {
                    bool limit = (i % 4 == 0) || (j % 4 == 0);
                    if (limit) return colorDark;
                    bool center = (i % 4 == 4/2) || (j % 4 == 4/2);
                    bool tileIsLight = ((i/4) ^ (j/4)) & 1;
                    if (center) return tileIsLight ? colorDark : colorLight;
                    return tileIsLight ? colorLight : colorDark;
                }

            case Pattern.TILES_ZEBRA:
                return ((i + j) / 2) & 1 ?  colorDark : colorLight;

            case Pattern.TILES_L:
                {
                    int which = (i & j) & 1;
                    return which ? colorLight : colorDark;
                }

            case Pattern.TILES_2x2_1x1:
                {
                    enum bitmap = [ 0, 1, 1,
                    1, 0, 0,
                    1, 0, 0 ];

                    return bitmap[(i % 3) * 3 + (j % 3)] ? colorLight : colorDark;
                }

            case Pattern.CROSS:
                {
                    enum bitmap = [ 0, 1, 1, 1, 0, 1, 0, 0, 0, 1,
                    0, 0, 1, 0, 1, 1, 1, 0, 1, 0,
                    0, 1, 0, 0, 0, 1, 0, 1, 1, 1,
                    1, 1, 1, 0, 1, 0, 0, 0, 1, 0,
                    0, 1, 0, 1, 1, 1, 0, 1, 0, 0,
                    1, 0, 0, 0, 1, 0, 1, 1, 1, 0,
                    1, 1, 0, 1, 0, 0, 0, 1, 0, 1,
                    1, 0, 1, 1, 1, 0, 1, 0, 0, 0,
                    0, 0, 0, 1, 0, 1, 1, 1, 0, 1,
                    1, 0, 1, 0, 0, 0, 1, 0, 1, 1 ];


                    return bitmap[(i % 10) * 10 + (j % 10)]  ? colorLight : colorDark;
                }

            case Pattern.HOLES:
                {
                    enum bitmap = [ 0, 0, 0, 1, 1, 1,
                    0, 1, 0, 1, 0, 1,
                    0, 0, 0, 1, 1, 1,
                    1, 1, 1, 0, 0, 0,
                    1, 0, 1, 0, 1, 0,
                    1, 1, 1, 0, 0, 0 ];

                    return bitmap[(i % 6) * 6 + (j % 6)] ? colorLight : colorDark;
                }
        }
    }
    if (pattern.swapIJ)
    {
        int temp = i;
        i = j;
        j = temp;        
    }
    if (pattern.swapColors)
    {
        vec3f temp = colorLight;
        colorLight = colorDark;
        colorDark = temp;
    }

    return subColor(i, j, pattern.pattern, colorLight, colorDark) + randomPerturbation(rng) * pattern.noiseAmount;
}
