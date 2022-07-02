#!/usr/bin/env python3
import argparse

import glob
import copy

import nltk
import textgrid as tg

nltk.download('punkt')

def find_repetitions(tier: tg.Tier, *, max_cache:int = 100) -> tg.Tier: 
    cache = []

    for interval in tier:
        if interval.text == "": continue

        cache.insert(0, interval.text)
        if len(cache) > max_cache: cache.pop()

        try: 
            interval.text = str(1/cache.index(interval.text, 1))
        except ValueError:
            interval.text = str(0)
    return tier

def find_frequencies(tier: tg.Tier) -> tg.Tier:
    fdist=nltk.FreqDist(nltk.word_tokenize(str(tier)))
    for interval in tier:
        if interval.text == "": continue
        interval.text = fdist.freq(interval.text)
    return tier

def parse_arguments() -> argparse.Namespace: 
    parser = argparse.ArgumentParser(description = "Processes alligned pos_tags .TextGrid files generated by pos_tagging.py to a .TextGrid with reptition information in it.")
    parser.add_argument("-d", "--directory", help = "The directory the pos_tags .TextGrid is expected in, and the output is saved to")
    parser.add_argument("-m", "--max_read", help = "The maximum amount of words the detector reads back to check for repetitions")
    return parser.parse_args()

def main(): 
    args: argparse.Namespace = parse_arguments()

    tagged_files = glob.glob(f"./{args.directory}/*.pos_tags.TextGrid")
    for file in tagged_files:
        tagged_grid = tg.TextGrid(filename = file)

        repetition_grid = tg.TextGrid()
        repetition_grid.xmin, repetition_grid.xmax = tagged_grid.xmin, tagged_grid.xmax
        repetition_grid["Repetitions"] = find_repetitions(copy.deepcopy(tagged_grid["POStags"]), max_cache = 300)
        repetition_grid["FreqDist"]    = find_frequencies(copy.deepcopy(tagged_grid["POStags"]))

        name = tagged_grid.filename.replace(".pos_tags.TextGrid", ".repetitions.TextGrid")
        repetition_grid.write(name)

if __name__ == "__main__":
    main()