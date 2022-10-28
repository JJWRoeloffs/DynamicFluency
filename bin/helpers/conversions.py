from __future__ import annotations

from praatio.data_classes.textgrid import Textgrid

from .textgridtier_extensions import replace_label

def pos_label_to_lemma_label(pos_label: str) -> str:
    """returns the lemma split from the full POS tag label."""
    return pos_label.split("_")[0]

def pos_tier_to_lemma_tier(pos_tier: Textgrid, name: str = "Lemmas") -> Textgrid:
    """Makes a lemma tier out of a pos_tagging made pos_tier"""
    lemma_list = [replace_label(entry, pos_label_to_lemma_label) for entry in pos_tier.entryList]
    return pos_tier.new(name=name, entryList=lemma_list)
