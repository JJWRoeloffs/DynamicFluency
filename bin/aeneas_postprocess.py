#!/usr/bin/env python3
import argparse

import os
import json
import glob

import textgrid as tg

class AeneasTextGrid(tg.TextGrid):
    def __init__(self):
        super().__init__()  

    def tier_from_aeneas(self, filepath: str, tier_name: str):
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

def parse_arguments() -> argparse.Namespace: 
    parser = argparse.ArgumentParser(description = "Processes tokens and phrases .json files generated by aeneas a .TextGrid")
    parser.add_argument("-d", "--directory", help = "The directory the tokens and phases is expected in, and the output is saved to")
    return parser.parse_args()


def main(): 
    args: argparse.Namespace = parse_arguments()

    word_allignments = glob.glob(f"./{args.directory}/*.tokens.json")
    phrase_allignments = glob.glob(f"./{args.directory}/*.phrases.json")

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