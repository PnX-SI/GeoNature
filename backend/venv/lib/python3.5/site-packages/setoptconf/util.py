import csv
import io
import sys


__all__ = (
    'csv_to_list',
    'UnicodeMixin',
)


def csv_to_list(value):
    if isinstance(value, str) and value:
        reader = csv.reader(io.StringIO(value))
        parsed = next(reader)
        return parsed
    return []


# Adapted from http://lucumr.pocoo.org/2011/1/22/forwards-compatible-python/
# pylint: disable=R0903
class UnicodeMixin(object):
    if sys.version_info >= (3, 0):
        __str__ = lambda x: x.__unicode__()
    else:
        __str__ = lambda x: str(x).encode('utf-8')
