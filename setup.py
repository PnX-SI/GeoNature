import setuptools
from pathlib import Path


root_dir = Path(__file__).absolute().parent
with (root_dir / "VERSION").open() as f:
    version = f.read().strip()
with (root_dir / "README.md").open() as f:
    long_description = f.read()


setuptools.setup(
    name="geonature",
    description="Application de saisie et de synthèse des observations faune et flore",
    long_description=long_description,
    long_description_content_type="text/markdown",
    maintainer="Parcs nationaux des Écrins et des Cévennes",
    maintainer_email="geonature@ecrins-parcnational.fr",
    url="https://github.com/PnX-SI/GeoNature/",
    python_requires=">=3.6",
    version=version,
    packages=setuptools.find_packages(where="backend", include=["geonature*"]),
    package_dir={
        "": "backend",
    },
    package_data={
        "geonature.tests": ["data/*.sql"],
        "geonature.migrations": ["data/**/*.sql"],
    },
    install_requires=list(open("backend/requirements-common.in", "r"))
    + list(open("backend/requirements-dependencies.in", "r")),
    extras_require={
        "tests": [
            "pytest",
            "pytest-flask",
            "pytest-cov",
            "jsonschema",
        ],
        "doc": [
            "sphinx",
            "sphinx_rtd_theme",
            "sphinxcontrib-httpdomain",
            "sphinxcontrib-websupport",
        ],
    },
    classifiers=[
        "Framework :: Flask",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.6",
    ],
    entry_points={
        "console_scripts": [
            "geonature = geonature.core.command:main",
        ],
    },
)
