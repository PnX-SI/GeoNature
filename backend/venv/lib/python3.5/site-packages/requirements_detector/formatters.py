
import sys


def requirements_file(requirements_list):
    for requirement in requirements_list:
        sys.stdout.write(requirement.pip_format())
        sys.stdout.write('\n')


FORMATTERS = {
    'requirements_file': requirements_file
}
