module aliasthis.lang.english;

import aliasthis.lang.lang;

class LangEnglish : Lang
{
    override string[] getIntroText()
    {
        return [
            "  Inside the palace, groans mingle with sad confusion, and, "~
            "deep within, the hollow halls howl "~
            "with women's cries: the clamour strikes the golden stars. \n\n"~
            "  Trembling mothers wander the vast building, clasping "~
            "the doorposts, and placing kisses on them. \n\n"~
            "  Pyrrhus drives forward, "~
            "with his father Achilles's strength, no barricades nor the guards "~
            "themselves can stop him: the door collapses under the ram's blows, "~
            "and the posts collapse, wrenched from their sockets. \n",


            "  Strength makes a road: the Greeks, pour through, force a passage, "~
            "slaughter the front ranks, and fill the wide space with their men. \n\n"~
            "  A foaming river is not so furious, when it floods, "~
            "bursting its banks, overwhelms the barriers against it, "~
            "and rages in a mass through the fields, sweeping cattle and stables "~
            "across the whole plain. \n",


            "  I saw Pyrrhus myself, on the threshold, mad with slaughter, and the two sons of Atreus. \n\n"~
            "  I saw Hecuba, her hundred women, and Priam at the altars, "~
            "polluting with blood the flames that he himself had sanctified. \n\n"~
            "  Those fifty chambers, the promise of so many offspring, the doorposts, "~
            "rich with spoils of barbarian gold, crash down: the Greeks possess what the fire spares. \n"
        ];
    }

    override string getEntryText()
    {
        return "You are Pyrrhus. Kill King Priam.";
    }

    override string[] mainMenuItems()
    {
        return
        [
            "New game",
            "Load game",
            "View recording",
            "Change language",
            "Quit"
        ];
    }

    override string getAeneid()
    {
      return "Aeneid Book II";
    }
}
