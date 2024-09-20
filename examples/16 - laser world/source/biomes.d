module biomes;


enum BiomeType : byte
{
    Empty, // Deep space
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
        case Ocean: return "<lgrey><blink><on_lblue>~</></></>";
        case ShallowSea: return "<white><blink><on_lblue>~</></></>";
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