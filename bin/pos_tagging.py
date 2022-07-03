#!/usr/bin/env python3
import argparse

import glob
from typing import Union, List

import nltk
import textgrid as tg

nltk.download('punkt', 'averaged_perceptron_tagger')

def parse_arguments() -> argparse.Namespace: 
    parser = argparse.ArgumentParser(description = "Creates a textgrid with a POS-tagged tier from an allignment textgrid")
    parser.add_argument("-d", "--directory", nargs='?', default="output", help = "The directory the tokens and phases is expected in, and the output is saved to")
    parser.add_argument("-a", "--allignment", help = "The type of allignment textgrid, either 'maus' or 'aeneas'")
    return parser.parse_args()


# Jankyness needed because the NLTK tokenise split sometimes splits words into smaller sub-sections, and pauses are empty intervals
def replace_labels(tier: tg.Tier, tags: List[Union[str, str]]) -> tg.Tier:
    for interval in tier:
        if not interval.text: continue
        
        word = ""
        while interval.text != word:
            label = ""
            word += tags[0][0]
            label = " ".join([label, "_".join(tags[0])])
            tags.pop(0)
        interval.text = label.strip()
    return tier
            

def main(): 
    args: argparse.Namespace = parse_arguments()

    if args.allignment == "maus": tokentier = "ORT-MAU"
    if args.allignment == "aeneas": tokentier = "Words"

    allignment_files = glob.glob(f"./{args.directory}/*.allignment.TextGrid")

    for file in allignment_files:
        allignment_grid = tg.TextGrid(filename = file)

        tokens: List[str] = nltk.word_tokenize(str(allignment_grid[tokentier]))
        tags: List[Union[str, str]] =  nltk.pos_tag(tokens)
        
        tagged = tg.TextGrid()
        tagged.xmin, tagged.xmax = allignment_grid.xmin, allignment_grid.xmax
        tagged["POStags"]: tg.Tier = replace_labels(allignment_grid[tokentier], tags)

        name = allignment_grid.filename.replace(".allignment.TextGrid", ".pos_tags.TextGrid")
        tagged.write(name)


if __name__ == "__main__":
    main()