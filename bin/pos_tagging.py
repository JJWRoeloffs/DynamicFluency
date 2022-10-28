#!/usr/bin/env python3
from __future__ import annotations

import glob
import argparse
from collections import namedtuple
from typing import List, Union

import nltk
from praatio import textgrid as tg
from praatio.data_classes.textgrid import Textgrid
from praatio.data_classes.textgrid_tier import TextgridTier

from helpers import replace_label, entrylist_labels_to_string, set_label

nltk.download('punkt')
nltk.download('averaged_perceptron_tagger')

def parse_arguments() -> argparse.Namespace: 
    parser = argparse.ArgumentParser(description = "Creates a textgrid with a POS-tagged tier from an allignment textgrid")
    parser.add_argument("-d", "--directory", nargs='?', default="output", help = "The directory the tokens and phases is expected in, and the output is saved to")
    parser.add_argument("-a", "--allignment", help = "The type of allignment textgrid, either 'maus' or 'aeneas'")
    return parser.parse_args()

def make_lowecase_entrylist(entryList: List[namedtuple]):
    return [replace_label(entry, lambda x: x.lower()) for entry in entryList]

def generate_tags_from_entrylist(
    entryList: List[namedtuple]
    ) -> List[Union[str, str]]:

    text = entrylist_labels_to_string(entryList)
    tokens: List[str] = nltk.word_tokenize(text)
    return nltk.pos_tag(tokens)

# Jankyness needed because the NLTK tokenise split sometimes splits words into smaller sub-sections
def allign_tags(
        tags: List[Union[str, str]],
        entryList: List[namedtuple] 
    ) -> List[namedtuple]:
    """Make an alligned entrylist out of NLTK generated pos_tags and the entryList those were generated from."""

    new_entryList = []
    for entry in entryList:
        if not entry.label: continue

        word = ""
        label = ""
        while entry.label != word:
            word += tags[0][0]
            label = " ".join([label, "_".join(tags[0])])
            tags.pop(0)

        new_entryList.append(set_label(entry, label.strip()))
    return new_entryList

def make_pos_tier(words_tier: TextgridTier, *, name: str = "POStags") -> TextgridTier:
    """Makes a POS tagged tier from a textgrid tier with alligned words"""
    lowercase_entryList = make_lowecase_entrylist(words_tier.entryList)
    
    tags = generate_tags_from_entrylist(lowercase_entryList)
    tag_entryList = allign_tags(tags, lowercase_entryList)

    return words_tier.new(name = name, entryList = tag_entryList)

def main():
    args: argparse.Namespace = parse_arguments()

    if args.allignment == "maus": 
        tokentier_name = "ORT-MAU"
    elif args.allignment == "aeneas":
        tokentier_name = "Words"
    else:
        raise ValueError(f"Unknown allignment type found: {args.allignment}")

    allignment_files = glob.glob(f"./{args.directory}/*.allignment.TextGrid")

    for file in allignment_files:
        allignment_grid = tg.openTextgrid(file, includeEmptyIntervals=True)

        tagged_tier = make_pos_tier(allignment_grid.tierDict[tokentier_name])

        tag_grid = Textgrid()
        tag_grid.addTier(tagged_tier)
        name = file.replace(".allignment.TextGrid", ".pos_tags.TextGrid")
        tag_grid.save(name, format="long_textgrid", includeBlankSpaces=True)

if __name__ == "__main__":
    main()
