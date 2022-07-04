#!/usr/bin/env python3
import argparse
import csv

import sqlite3
import pandas as pd

def parse_arguments() -> argparse.Namespace: 
    parser = argparse.ArgumentParser(description = "Creates a SQLite3 database from a SUBTLEXus .txt file")
    parser.add_argument("-b", "--database", nargs='?', default="subtlexus/subtlexus.db", help = "File used for the SQLite Database.")
    parser.add_argument("-f", "--subtlexus_file", nargs='?', default="SUBTLEXus74286wordstextversion.txt", help = "SUBTLEXus .txt tab seperated file location.")
    return parser.parse_args()

def main():
    args: argparse.Namespace = parse_arguments()

    try:
        subtlexus = sqlite3.connect(args.database)

        with open('resources/subtlexus_init.sql') as queryfile:
            query = queryfile.read()
        cursor = subtlexus.cursor()
        cursor.execute(query)

        with open(args.subtlexus_file, 'r') as tsv:
            dr = csv.DictReader(tsv, delimiter="\t")
            data = [
                (
                    i["Word"], 
                    i["FREQcount"], 
                    i["CDcount"], 
                    i["FREQlow"], 
                    i["Cdlow"], 
                    i["SUBTLWF"], 
                    i["Lg10WF"], 
                    i["SUBTLCD"], 
                    i["Lg10CD"]
                )
                for i in dr
            ]
        cursor.executemany(
            """INSERT INTO subtlexus (
                    word, 
                    freq_count, 
                    cd_count, 
                    freq_low, 
                    cd_low, 
                    subtlwf, 
                    lg10wf, 
                    subtlcd, 
                    lg10cd
                ) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);""", 
            data
        ) 

        subtlexus.commit() 
        cursor.close()

    except sqlite3.Error as error:
        print('SQL Error occured - ', error)

    finally:
        if subtlexus:
            subtlexus.close()


if __name__ == "__main__":
    main()