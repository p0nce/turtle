module aliasthis.lang.french;

import aliasthis.lang.lang;

class LangFrench : Lang
{
    override string[] getIntroText()
    {
        return [

            // 0
            "  L'intérieur du palais n'est que gémissements, tumulte et douleur. "~
            "Toutes les cours hurlent du cri lamentable des femmes : "~
            "la clameur va frapper les astres d'or.\n\n"~

            "  Les mères épouvantées errent ça et là dans les immenses galeries ; elles embrassent, "~
            "étreignent les portes, elles y collent leurs lèvres. \n\n"~

            "  Pyrrhus, aussi fougueux que son père, presse l'attaque : ni barres de fer "~
            "ni gardiens ne peuvent soutenir l'assaut. Les coups redoublés du "~
            "bélier font éclater les portes et sauter les montants de leurs gonds. ",
                
            // 1
            "  La violence se fraie la voie. Le torrent des Grecs force les entrées ; "~
            "ils massacrent les premiers qu'ils rencontrent ; et les vastes demeures "~
            "se remplissent de soldats.\n\n"~
            "  Quand, ses digues rompues, un fleuve écumant est sorti de son lit, "~
            "et a surmonté de ses remous profonds les masses qui lui faisaient obstacle, "~
            "c'est avec moins de fureur qu'il déverse sur les champs ses eaux "~
            "amoncelées et qu'il entraîne par toute la campagne les grands troupeaux et leurs étables. ",

            // 2
            "  J'ai vu de mes yeux, ivre de carnage, "~
            "Néoptolème et sur le seuil les deux Atrides.\n\n"~
            "  J'ai vu Hécube et ses cent brus, et au pied des autels Priam dont le sang profanait les "~
            "feux sacrés qu'il avait lui-même allumés.\n\n"~
            "  Ces cinquante chambres nuptiales, vaste espoir de postérité, leurs portes "~
            "superbement chargées des dépouilles et de l'or des Barbares, "~
            "tout s'est effondré. \n\n Les Grecs sont partout où n'est pas la flamme. "
        ];
    }

    override string getEntryText()
    {
        return "Vous êtes Pyrrhus. Tuez le roi Priam.";
    }

    override string[] mainMenuItems()
    {
        return
        [
            "Nouveau jeu",
            "Charger jeu",
            "Voir replay",
            "Changer langue",
            "Quitter"
        ];
    }

    override string getAeneid()
    {
        return "Enéide Livre II";
    }
}
