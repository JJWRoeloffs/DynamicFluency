#!/usr/bin/env python3
import argparse

import sqlite3
import glob
import copy

import textgrid as tg

def parse_arguments() -> argparse.Namespace: 
    parser = argparse.ArgumentParser(description = "Reads word frequencies frim a SQLite3 database of SUBTLEXus")
    parser.add_argument("-b", "--database", nargs='?', default="subtlexus/subtlexus.db", help = "File used for the SQLite Database.")
    parser.add_argument("-d", "--directory", nargs='?', default="output", help = "The directory the pos_tags .TextGrid is expected in, and the output is saved to")
    return parser.parse_args()

# TODO: Make this function not hideous and hard-coded with the database provided
def get_frequencies(tier: tg.Tier, database: str) -> tg.TextGrid:
    try:
        sql_database = sqlite3.connect(database)   
        cursor = sql_database.cursor()

        grid = tg.TextGrid()
        grid.xmax, grid.xmin = tier.xmax, tier.xmin

        grid["FREQcount"] = copy.deepcopy(tier)
        grid["CDcount"]   = copy.deepcopy(tier)
        grid["FREQlow"]   = copy.deepcopy(tier)
        grid["Cdlow"]     = copy.deepcopy(tier)
        grid["SUBTLWF"]   = copy.deepcopy(tier)
        grid["Lg10WF"]    = copy.deepcopy(tier)
        grid["SUBTLCD"]   = copy.deepcopy(tier)
        grid["Lg10CD"]    = copy.deepcopy(tier)

        for i, interval in enumerate(tier):
            if interval.text == "": continue

            cursor.execute(
                "SELECT * FROM subtlexus WHERE word = (?);", [interval.text.split("_")[0].lower()]
            )
            try:
                data = cursor.fetchall()[0] 
            except IndexError:
                data = [""] * 9   
            grid["FREQcount"][i].text = data[1]
            grid["CDcount"][i].text   = data[2]
            grid["FREQlow"][i].text   = data[3]
            grid["Cdlow"][i].text     = data[4]
            grid["SUBTLWF"][i].text   = data[5]
            grid["Lg10WF"][i].text    = data[6]
            grid["SUBTLCD"][i].text   = data[7]
            grid["Lg10CD"][i].text    = data[8]

        return grid

    except sqlite3.Error as error:
        print('SQL Error occured - ', error)

    finally:
        if sql_database:
            sql_database.close()

def main(): 
    args: argparse.Namespace = parse_arguments()

    tagged_files = glob.glob(f"./{args.directory}/*.pos_tags.TextGrid")
    for file in tagged_files:
        tagged_grid = tg.TextGrid(filename = file)

        frequency_grid = get_frequencies(copy.deepcopy(tagged_grid["POStags"]), args.database)

        name = tagged_grid.filename.replace(".pos_tags.TextGrid", ".frequencies.TextGrid")
        frequency_grid.write(name)

if __name__ == "__main__":
    main()