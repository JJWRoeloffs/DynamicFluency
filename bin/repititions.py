#!/usr/bin/env python3
import argparse

import glob
import copy

import nltk
import textgrid as tg

nltk.download('punkt')

def parse_arguments() -> argparse.Namespace: 
    parser = argparse.ArgumentParser(description = "Processes alligned pos_tags .TextGrid files generated by pos_tagging.py to a .TextGrid with reptition information in it.")
    parser.add_argument("-d", "--directory", nargs='?', default="output", help = "The directory the pos_tags .TextGrid is expected in, and the output is saved to")
    parser.add_argument("-m", "--max_read", nargs='?', default=300, type=int, help = "The maximum amount of words the detector reads back to check for repetitions")
    parser.add_argument("-i", "--to_ignore", nargs='?', help = "The words to ignore and not assign any value, seperated by commas.")

    args: argparse.Namespace = parser.parse_args()
    if args.to_ignore:
        args.to_ignore = set(args.to_ignore.split(","))
    else:
        args.to_ignore = set()
    return args

def find_repetitions(tier: tg.Tier, *, max_cache:int = 100, to_ignore: set) -> tg.Tier: 
    cache = []

    for interval in tier:
        if interval.text == "": continue
        if interval.text in to_ignore: continue

        cache.insert(0, interval.text)
        if len(cache) > max_cache: cache.pop()

        try: 
            interval.text = str(1/cache.index(interval.text, 1))
        except ValueError:
            interval.text = str(0)
    return tier

def find_frequencies(tier: tg.Tier, *, to_ignore: set) -> tg.Tier:
    fdist=nltk.FreqDist(nltk.word_tokenize(str(tier)))
    for interval in tier:
        if interval.text == "": continue
        if interval.text in to_ignore: continue
        interval.text = fdist.freq(interval.text)
    return tier

def main(): 
    args: argparse.Namespace = parse_arguments()

    tagged_files = glob.glob(f"./{args.directory}/*.pos_tags.TextGrid")
    for file in tagged_files:
        tagged_grid = tg.TextGrid(filename = file)

        repetition_grid = tg.TextGrid()
        repetition_grid.xmin, repetition_grid.xmax = tagged_grid.xmin, tagged_grid.xmax
        repetition_grid["Repetitions"] = find_repetitions(copy.deepcopy(tagged_grid["POStags"]), max_cache = args.max_read, to_ignore=args.to_ignore)
        repetition_grid["FreqDist"]    = find_frequencies(copy.deepcopy(tagged_grid["POStags"]), to_ignore=args.to_ignore)

        name = tagged_grid.filename.replace(".pos_tags.TextGrid", ".repetitions.TextGrid")
        repetition_grid.write(name)

if __name__ == "__main__":
    main()