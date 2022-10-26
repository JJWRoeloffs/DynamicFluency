#!/usr/bin/env python3
import argparse

import sqlite3
import glob
import copy

import textgrid as tg

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

def create_frequencies_textgrid(tier: tg.Tier, database_file: str, table_name: str, *, to_ignore: set) -> tg.TextGrid:
    grid = tg.TextGrid()
    grid.xmax, grid.xmin = tier.xmax, tier.xmin

    try:
        database = sqlite3.connect(database_file)   
        cursor = database.cursor()

        # Get column names from table
        cursor.execute("SELECT name FROM PRAGMA_TABLE_INFO(?);", [table_name])
        column_names = [name[0] for name in cursor.fetchall()]

        # Create a tier for each column
        for name in column_names:
            grid[name] = copy.deepcopy(tier)

        # Set values from database to textgird for each word, for each tier/column.
        for i, interval in enumerate(tier):
            if interval.text == "": continue
            if interval.text in to_ignore: continue
            
            #Reading from the POS tags, the lemmas need to be seperated from their part of speech.
            lemma = interval.text.split("_")[0]
            
            # Using f-strings for the table, as the buildin trows an error.
            cursor.execute(
                f"SELECT DISTINCT * FROM {table_name} WHERE LOWER(Lemma) LIKE LOWER((?));", [lemma]
            )
            try:
                data = cursor.fetchall()[0]
            except IndexError:
                data = ["Missing"] * len(column_names)

            for name, value in zip(column_names, data):
                grid[name][i].text = value

        # Remove the lemmas from the TextGrid, as they would be superfluous; they are already in the textgird used as imput
        grid.pop("Lemma")
        return grid

    except sqlite3.Error as error:
        print('SQL Error occured - ', error)

    finally:
        if database:
            database.close()

def main(): 
    args: argparse.Namespace = parse_arguments()

    tagged_files = glob.glob(f"./{args.directory}/*.pos_tags.TextGrid")
    for file in tagged_files:
        tagged_grid = tg.TextGrid(filename = file)

        frequency_grid = create_frequencies_textgrid(tagged_grid["POStags"], args.database, args.table_name, to_ignore = args.to_ignore)

        name = tagged_grid.filename.replace(".pos_tags.TextGrid", ".frequencies.TextGrid")
        frequency_grid.write(name)

if __name__ == "__main__":
    main()