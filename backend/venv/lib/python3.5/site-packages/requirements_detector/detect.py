import re
import os
import sys
from astroid.builder import AstroidBuilder
from astroid import MANAGER, CallFunc, Name, Assign, Keyword, List, Tuple, Const, AssName
from requirements_detector.requirement import DetectedRequirement


__all__ = ['find_requirements',
           'RequirementsNotFound',
           'CouldNotParseRequirements']


# PEP263, see http://legacy.python.org/dev/peps/pep-0263/
_ENCODING_REGEXP = re.compile(r'coding[:=]\s*([-\w.]+)')


_PY3K = sys.version_info >= (3, 0)


_PIP_OPTIONS = (
    '-i', '--index-url',
    '--extra-index-url',
    '--no-index',
    '-f', '--find-links',
    '-r'
)


class RequirementsNotFound(Exception):
    pass


class CouldNotParseRequirements(Exception):
    pass


def _load_file_contents(filepath):
    # This function is a bit of a tedious workaround (AKA 'hack').
    # Astroid calls 'compile' under the hood, which refuses to accept a Unicode
    # object which contains a PEP-263 encoding definition. However if we give
    # Astroid raw bytes, it'll assume ASCII. Therefore we need to detect the encoding
    # here, convert the file contents to a Unicode object, *and also strip the encoding
    # declaration* to avoid the compile step breaking.
    with open(filepath) as f:
        if _PY3K:
            return f.read()
        
        contents = f.readlines()

        result = []
        encoding_lines = contents[0:2]
        encoding = 'utf-8'
        for line in encoding_lines:
            match = _ENCODING_REGEXP.search(line)
            if match is None:
                result.append(line.strip())
            else:
                encoding = match.group(1)

        result += [line.rstrip() for line in contents[2:]]
        result = '\n'.join(result)
        return result.decode(encoding)


def find_requirements(path):
    """
    This method tries to determine the requirements of a particular project
    by inspecting the possible places that they could be defined.

    It will attempt, in order:

    1) to parse setup.py in the root for an install_requires value
    2) to read a requirements.txt file or a requirements.pip in the root
    3) to read all .txt files in a folder called 'requirements' in the root
    4) to read files matching "*requirements*.txt" and "*reqs*.txt" in the root,
       excluding any starting or ending with 'test'

    If one of these succeeds, then a list of pkg_resources.Requirement's
    will be returned. If none can be found, then a RequirementsNotFound
    will be raised
    """
    requirements = []

    setup_py = os.path.join(path, 'setup.py')
    if os.path.exists(setup_py) and os.path.isfile(setup_py):
        try:
            requirements = from_setup_py(setup_py)
            requirements.sort()
            return requirements
        except CouldNotParseRequirements:
            pass

    for reqfile_name in ('requirements.txt', 'requirements.pip'):
        reqfile_path = os.path.join(path, reqfile_name)
        if os.path.exists(reqfile_path) and os.path.isfile(reqfile_path):
            try:
                requirements += from_requirements_txt(reqfile_path)
            except CouldNotParseRequirements as e:
                pass

    requirements_dir = os.path.join(path, 'requirements')
    if os.path.exists(requirements_dir) and os.path.isdir(requirements_dir):
        from_dir = from_requirements_dir(requirements_dir)
        if from_dir is not None:
            requirements += from_dir

    from_blob = from_requirements_blob(path)
    if from_blob is not None:
        requirements += from_blob

    requirements = list(set(requirements))
    if len(requirements) > 0:
        requirements.sort()
        return requirements

    raise RequirementsNotFound


class SetupWalker(object):

    def __init__(self, ast):
        self._ast = ast
        self._setup_call = None
        self._top_level_assigns = {}
        self.walk()

    def walk(self, node=None):
        top = node is None
        node = node or self._ast

        # test to see if this is a call to setup()
        if isinstance(node, CallFunc):
            for child_node in node.get_children():
                if isinstance(child_node, Name) and child_node.name == 'setup':
                    # TODO: what if this isn't actually the distutils setup?
                    self._setup_call = node

        for child_node in node.get_children():
            if top and isinstance(child_node, Assign):
                for target in child_node.targets:
                    if isinstance(target, AssName):
                        self._top_level_assigns[target.name] = child_node.value
            self.walk(child_node)

    def _get_list_value(self, list_node):
        values = []
        for child_node in list_node.get_children():
            if not isinstance(child_node, Const):
                # we can't handle anything fancy, only constant values
                raise CouldNotParseRequirements
            values.append(child_node.value)
        return values

    def get_requires(self):
        # first, if we have a call to setup, then we can see what its "install_requires" argument is
        if not self._setup_call:
            raise CouldNotParseRequirements

        found_requirements = []

        for child_node in self._setup_call.get_children():
            if not isinstance(child_node, Keyword):
                # do we want to try to handle positional arguments?
                continue

            if child_node.arg not in ('install_requires', 'requires'):
                continue

            if isinstance(child_node.value, (List, Tuple)):
                # joy! this is a simple list or tuple of requirements
                # this is a Keyword -> List or Keyword -> Tuple
                found_requirements += self._get_list_value(child_node.value)
                continue

            if isinstance(child_node.value, Name):
                # otherwise, it's referencing a value defined elsewhere
                # this will be a Keyword -> Name
                try:
                    reqs = self._top_level_assigns[child_node.value.name]
                except KeyError:
                    raise CouldNotParseRequirements
                else:
                    if isinstance(reqs, (List, Tuple)):
                        found_requirements += self._get_list_value(reqs)
                        continue

            # otherwise it's something funky and we can't handle it
            raise CouldNotParseRequirements

        # if we've fallen off the bottom with nothing in our list of requirements,
        #  we simply didn't find anything useful
        if len(found_requirements) > 0:
            return found_requirements
        raise CouldNotParseRequirements


def from_setup_py(setup_file):
    try:
        from astroid import AstroidBuildingException
    except ImportError:
        syntax_exceptions = (SyntaxError,)
    else:
        syntax_exceptions = (SyntaxError, AstroidBuildingException)

    try:
        contents = _load_file_contents(setup_file)
        ast = AstroidBuilder(MANAGER).string_build(contents)
    except syntax_exceptions:
        # if the setup file is broken, we can't do much about that...
        raise CouldNotParseRequirements

    walker = SetupWalker(ast)

    requirements = []
    for req in walker.get_requires():
        requirements.append(DetectedRequirement.parse(req, setup_file))

    return requirements


def from_requirements_txt(requirements_file):
    # see http://www.pip-installer.org/en/latest/logic.html
    requirements = []
    with open(requirements_file) as f:
        for req in f.readlines():
            if req.strip() == '':
                # empty line
                continue
            if req.strip().startswith('#'):
                # this is a comment
                continue
            if req.strip().split()[0] in _PIP_OPTIONS:
                # this is a pip option
                continue
            detected = DetectedRequirement.parse(req, requirements_file)
            if detected is None:
                continue
            requirements.append(detected)

    return requirements


def from_requirements_dir(path):
    requirements = []
    for entry in os.listdir(path):
        filepath = os.path.join(path, entry)
        if not os.path.isfile(filepath):
            continue
        if entry.endswith('.txt') or entry.endswith('.pip'):
            # TODO: deal with duplicates
            requirements += from_requirements_txt(filepath)

    return requirements


def from_requirements_blob(path):
    requirements = []

    for entry in os.listdir(path):
        filepath = os.path.join(path, entry)
        if not os.path.isfile(filepath):
            continue
        m = re.match(r'^(\w*)req(uirement)?s(\w*)\.txt$', entry)
        if m is None:
            continue
        if m.group(1).startswith('test') or m.group(3).endswith('test'):
            continue
        requirements += from_requirements_txt(filepath)

    return requirements
