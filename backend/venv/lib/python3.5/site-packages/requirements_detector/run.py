import os
import sys
from requirements_detector.detect import RequirementsNotFound
from requirements_detector.formatters import FORMATTERS
from requirements_detector import find_requirements


def _die(message):
    sys.stderr.write("%s\n" % message)
    sys.exit(1)


def run():
    if len(sys.argv) > 1:
        path = sys.argv[1]
    else:
        path = os.getcwd()

    if not os.path.exists(path):
        _die("%s does not exist" % path)

    if not os.path.isdir(path):
        _die("%s is not a directory" % path)

    try:
        requirements = find_requirements(path)
    except RequirementsNotFound:
        _die("Unable to find requirements at %s" % path)

    format_name = 'requirements_file'  # TODO: other output formats such as JSON
    FORMATTERS[format_name](requirements)
    sys.exit(0)


if __name__ == '__main__':
    run()
