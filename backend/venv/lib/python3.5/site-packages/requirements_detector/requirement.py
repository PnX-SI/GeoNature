"""
This module represents the various types of requirement that can be specified for
a project. It is somewhat redundant to re-implement here as we could use
`pip.req.InstallRequirement`, but that would require depending on pip which is not
easy to do since it will usually be installed by the user at a specific version.
Additionally, the pip implementation has a lot of extra features that we don't need -
we don't expect relative file paths to exist, for example. Note that the parsing here
is also intentionally more lenient - it is not our job to validate the requirements
list.
"""
import os
import re
from pkg_resources import Requirement

try:
    import urlparse
except ImportError:
    # python3
    from urllib import parse as urlparse


def _is_filepath(req):
    # this is (probably) a file
    return os.path.sep in req or req.startswith('.')


def _parse_egg_name(url_fragment):
    """
    >>> _parse_egg_name('egg=fish&cake=lala')
    fish
    >>> _parse_egg_name('something_spurious')
    None
    """
    if '=' not in url_fragment:
        return None
    parts = urlparse.parse_qs(url_fragment)
    if 'egg' not in parts:
        return None
    return parts['egg'][0]  # taking the first value mimics pip's behaviour


def _strip_fragment(urlparts):
    new_urlparts = (
        urlparts.scheme,
        urlparts.netloc,
        urlparts.path,
        urlparts.params,
        urlparts.query,
        None
    )
    return urlparse.urlunparse(new_urlparts)


class DetectedRequirement(object):

    def __init__(self, name=None, url=None, requirement=None, location_defined=None):
        if requirement is not None:
            self.name = requirement.key
            self.requirement = requirement
            self.version_specs = requirement.specs
            self.url = None
        else:
            self.name = name
            self.version_specs = []
            self.url = url
            self.requirement = None
        self.location_defined = location_defined

    def _format_specs(self):
        return ','.join(['%s%s' % (comp, version) for comp, version in self.version_specs])

    def pip_format(self):
        if self.url:
            if self.name:
                return '%s#egg=%s' % (self.url, self.name)
            return self.url
        if self.name:
            if self.version_specs:
                return "%s%s" % (self.name, self._format_specs())
            return self.name

    def __str__(self):
        rep = self.name or 'Unknown'
        if self.version_specs:
            specs = ','.join(['%s%s' % (comp, version) for comp, version in self.version_specs])
            rep = '%s%s' % (rep, specs)
        if self.url:
            rep = '%s (%s)' % (rep, self.url)
        return rep

    def __hash__(self):
        return hash(str(self.name) + str(self.url) + str(self.version_specs))

    def __repr__(self):
        return 'DetectedRequirement:%s' % str(self)

    def __eq__(self, other):
        return self.name == other.name and self.url == other.url and self.version_specs == other.version_specs

    def __gt__(self, other):
        return (self.name or "") > (other.name or "")

    @staticmethod
    def parse(line, location_defined=None):
        # the options for a Pip requirements file are:
        #
        # 1) <dependency_name>
        # 2) <dependency_name><version_spec>
        # 3) <vcs_url>(#egg=<dependency_name>)?
        # 4) <url_to_archive>(#egg=<dependency_name>)?
        # 5) <path_to_dir>
        # 6) (-e|--editable) <path_to_dir>(#egg=<dependency_name)?
        # 7) (-e|--editable) <vcs_url>#egg=<dependency_name>
        line = line.strip()

        # strip the editable flag
        line = re.sub('^(-e|--editable) ', '', line)

        url = urlparse.urlparse(line)

        # if it is a VCS URL, then we want to strip off the protocol as urlparse
        # might not handle it correctly
        vcs_scheme = None
        if '+' in url.scheme or url.scheme in ('git',):
            if url.scheme == 'git':
                vcs_scheme = 'git+git'
            else:
                vcs_scheme = url.scheme
            url = urlparse.urlparse(re.sub(r'^%s://' % re.escape(url.scheme), '', line))

        if vcs_scheme is None and url.scheme == '' and not _is_filepath(line):
            # if we are here, it is a simple dependency
            try:
                req = Requirement.parse(line)
            except ValueError:
                # this happens if the line is invalid
                return None
            else:
                return DetectedRequirement(requirement=req, location_defined=location_defined)

        # otherwise, this is some kind of URL
        name = _parse_egg_name(url.fragment)
        url = _strip_fragment(url)

        if vcs_scheme:
            url = '%s://%s' % (vcs_scheme, url)

        return DetectedRequirement(name=name, url=url, location_defined=location_defined)
