import re
import codecs


STRING_VALS = (
    (
        'aws_secret_key',
        'Amazon Web Services secret key',
        (
            re.compile(r'(\'|")[A-Za-z0-9\\\+]{40}(\'|")'),
            re.compile(r'(\b|_)AWS(\b|_)', re.IGNORECASE)
        ),
        all
    ),
)

LINE_VALS = (
    (
        'diff',
        'Possible SCM diff in code',
        (
            re.compile(r'^<<<<<<< .*$'),
            re.compile(r'^>>>>>>> .*$')
        ),
    ),
    (
        'ssh_rsa_private_key',
        'Possible SSH private key',
        re.compile(r'^-{5}(BEGIN|END)\s+RSA\s+PRIVATE\s+KEY-{5}$')
    ),
    (
        'ssh_rsa_public_key',
        'Possible SSH public key',
        re.compile('^ssh-rsa\s+AAAA[0-9A-Za-z+/]+[=]{0,3}\s*([^@]+@[^@]+)?$')
    ),
)

VAR_NAMES = (
    (
        'password',
        'Possible hardcoded password',
        re.compile(r'(\b|[A-Z0-9_]*_)PASSWORD(_[A-Z0-9_]*|\b)\s*=\s(\'|")[^\'"]+(\'|")')
    ),
    (
        'secret',
        'Possible hardcoded secret key',
        re.compile(r'(\b|[A-Z0-9_]*_)SECRET(_[A-Z0-9_]*|\b)\s*=\s(\'|")[^\'"]+(\'|")')
    ),
)


def check_line(line, check_list):
    messages = []

    for tup in check_list:
        if len(tup) == 3:
            key, msg, regexps = tup
            cond = any
        else:
            key, msg, regexps, cond = tup

        if not isinstance(regexps, (list, tuple)):
            regexps = [regexps]
        if cond([regexp.search(line) for regexp in regexps]):
            messages.append((key, msg))

    return messages


def check_file(filepath):
    with codecs.open(filepath, 'r', 'utf-8') as to_check:
        return check_file_contents(to_check.read())


def check_file_contents(file_contents):
    messages = []

    for line_number0, line in enumerate(file_contents.split('\n')):
        for check_list in (STRING_VALS, LINE_VALS, VAR_NAMES):
            messages += [(line_number0+1, key, msg) for key, msg in check_line(line, check_list)]

    return messages
