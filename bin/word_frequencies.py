#!/usr/bin/env python3
import argparse

import glob
import sqlite3
from typing import Set, List

from praatio import textgrid as tg
from praatio.data_classes.textgrid import Textgrid
from praatio.data_classes.textgrid_tier import TextgridTier

from helpers import pos_tier_to_lemma_tier, set_all_tiers_static, set_all_tiers_from_dict

def parse_arguments() -> argparse.Namespace: 
    parser = argparse.ArgumentParser(description = "Reads word frequencies from an SQLite3 database. Assumes lemmas are in a column called \"Lemma\"")
    requiredNamed = parser.add_argument_group('Required named arguments')

    requiredNamed.add_argument("-t", "--table_name", help = "Name of the table to be read from.", required=True)

    parser.add_argument("-b", "--database", nargs='?', default="databases/main.db", help = "File used for the SQLite Database.")
    parser.add_argument("-d", "--directory", nargs='?', default="output", help = "The directory the pos_tags .TextGrid is expected in, and the output is saved to")
    parser.add_argument("-i", "--to_ignore", nargs='?', help = "The words to ignore and not assign any value, seperated by commas.")

    args: argparse.Namespace = parser.parse_args()
    if args.to_ignore:
        args.to_ignore = set(args.to_ignore.split(","))
    else:
        args.to_ignore = set()
    return args

def connect_to_database(database_file: str) -> sqlite3.Cursor:
    """Connects to the specifed sqlite3 database with a row-based cursor."""
    database = sqlite3.connect(database_file)
    database.row_factory = sqlite3.Row
    return database.cursor()

def get_column_names(cursor: sqlite3.Cursor, *, table_name: str) -> List[str]:
    """Returns all the column names from the specified table"""
    cursor.execute("SELECT name FROM PRAGMA_TABLE_INFO(?);", [table_name])
    return [name[0] for name in cursor.fetchall()]

def make_empty_frequency_grid(
        *,
        cursor: sqlite3.Cursor,
        table_name: str,
        base_tier: TextgridTier
    ) -> Textgrid:
    """Makes an "empty" frequency grid.
    This is a grid that has all the tiers initialised according to the column names of the databse,
    but does not have any values in those tiers, all of them being copies from the base."""
    frequency_grid = Textgrid()
    for name in get_column_names(cursor, table_name=table_name):
        tier = base_tier.new(name=name)
        frequency_grid.addTier(tier)
    return frequency_grid

def set_labels_from_db(
        *,
        cursor: sqlite3.Cursor,
        grid: Textgrid,
        table_name: str,
        lemma: str,
        index: int
    ) -> None:
    """Sets the tiers of a textgrid with one tier for every databse column to their respecive entries at an index"""

    cursor.execute(
        f"SELECT DISTINCT * FROM {table_name} WHERE LOWER(Lemma) LIKE LOWER((?));", [lemma]
    )

    try:
        row = cursor.fetchall()[0]
    except IndexError:
        set_all_tiers_static(grid, item="MISSING", index=index)
    else:
        set_all_tiers_from_dict(grid, items=row, index=index)

def create_frequency_grid(
        lemma_tier: TextgridTier,
        *,
        cursor: sqlite3.Cursor,
        table_name: str,
        to_ignore: Set
    ) -> Textgrid:
    """Create frequency grid from database connection"""

    frequency_grid = make_empty_frequency_grid(
        cursor = cursor,
        table_name = table_name,
        base_tier = lemma_tier
    )

    for i, entry in enumerate(lemma_tier.entryList):
        if (not entry.label) or (entry.label in to_ignore):
            set_all_tiers_static(frequency_grid, item="", index=i)
        else:
            set_labels_from_db(
                cursor = cursor,
                grid = frequency_grid,
                table_name = table_name,
                lemma = entry.label,
                index = i
            )

    return frequency_grid


def main(): 
    args: argparse.Namespace = parse_arguments()

    tagged_files = glob.glob(f"./{args.directory}/*.pos_tags.TextGrid")
    for file in tagged_files:
        tagged_grid = tg.openTextgrid(file, includeEmptyIntervals=True)
        lemma_tier = pos_tier_to_lemma_tier(tagged_grid.tierDict["POStags"])

        try:
            cursor = connect_to_database(args.database)
            frequency_grid = create_frequency_grid(
                lemma_tier   = lemma_tier,
                cursor = cursor,
                table_name = args.table_name,
                to_ignore  = args.to_ignore
            )
        finally:
            cursor.connection.close()
        
        frequency_grid.removeTier("Lemma")

        name = file.replace(".pos_tags.TextGrid", ".frequencies.TextGrid")
        frequency_grid.save(name, format="long_textgrid", includeBlankSpaces=True)

if __name__ == "__main__":
    main()
