import os
import json
import glob

import textgrid as tg

class AeneasTextGrid(tg.TextGrid):
    def __init__(self):
        super().__init__()  

    def tier_from_aeneas(self, filepath, tier_name):
        tier = tg.Tier()
        with open(filepath, "r") as file:   
            allignment = json.load(file)
            for fragment in allignment["fragments"]:
                xmin = float(fragment["begin"])
                xmax = float(fragment["end"])
                text = " ".join(fragment["lines"])

                if tier.xmax < xmax: tier.xmax = xmax
                if self.xmax < xmax: self.xmax = xmax  

                tier.append(tg.Interval(text, xmin, xmax))
        self[tier_name] = tier

def main(): 
    word_allignments = glob.glob("./output/*.tokens.json")
    phrase_allignments = glob.glob("./output/*.phrases.json")

    for i in range(len(word_allignments)):
        grid = AeneasTextGrid()
        grid.tier_from_aeneas(word_allignments[i], "Words")
        grid.tier_from_aeneas(phrase_allignments[i], "Phrases")

        name = word_allignments[i].replace(".tokens.json", ".allignment.TextGrid")
        grid.write(name)

        os.remove(word_allignments[i])
        os.remove(phrase_allignments[i])

if __name__ == "__main__":
    main()