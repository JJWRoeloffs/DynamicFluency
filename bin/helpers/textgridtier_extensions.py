from __future__ import annotations

from typing import Callable, List
from collections import namedtuple

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

