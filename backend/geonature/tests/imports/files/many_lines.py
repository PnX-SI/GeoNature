#!/usr/bin/env python

import csv
from argparse import ArgumentParser, FileType


def many_lines(source, dest, count):
    dialect = csv.Sniffer().sniff(source.readline())
    source.seek(0)
    reader = csv.reader(source, dialect=dialect)
    columns = next(reader)
    line = next(reader)

    writer = csv.writer(dest, dialect=dialect, quoting=csv.QUOTE_ALL)
    writer.writerow(columns)
    for i in range(count):
        writer.writerow(line)


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("--source", default="one_line.csv", type=FileType("r"))
    parser.add_argument("--dest", default="many_lines.csv", type=FileType("w"))
    parser.add_argument("--count", default=100000, type=int)
    args = parser.parse_args()
    many_lines(**vars(args))
