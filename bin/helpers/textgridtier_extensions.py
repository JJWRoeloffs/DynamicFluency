from __future__ import annotations

from typing import Callable, List, Dict
from collections import namedtuple

from praatio.data_classes.textgrid import Textgrid

def replace_label(entry: namedtuple, f: Callable) -> namedtuple:
    """Returns a new namedtuple with the "label" attribute changed according to passed function."""
    as_dict = entry._asdict()
    new_label = f(as_dict.pop("label"))
    return entry.__class__(label=new_label, **as_dict)

def set_label(entry: namedtuple, s: str) -> namedtuple:
    """Returns a new namedtuple with the "label" attribute changed to the passed one"""
    as_dict = entry._asdict()
    as_dict.pop("label")
    return entry.__class__(label=s, **as_dict)

def entrylist_labels_to_string(entryList: List[namedtuple]) -> str:
    """Make a single space-seperated string, out of the labels of an entryList
    Useful to make a "sentence" out of the words in the tier."""
    return " ".join([entry.label for entry in entryList])

def set_all_tiers_static(grid: Textgrid, *, item: str, index: int) -> None:
    """Sets the given index of all tiers' label of given grid to given value"""
    for tier in grid.tierDict:
        grid.tierDict[tier].entryList[index] = set_label(grid.tierDict[tier].entryList[index], item)

def set_all_tiers_from_dict(grid: Textgrid, *, items: Dict[str, str], index: int) -> None:
    """Sets the given index of all tiers' label of given grid to given value"""
    for tier in grid.tierDict:
        grid.tierDict[tier].entryList[index] = set_label(grid.tierDict[tier].entryList[index], str(items[tier]))

