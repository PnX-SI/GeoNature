import setuptools
from pathlib import Path


root_dir = Path(__file__).absolute().parent
with (root_dir / "VERSION").open() as f:
    version = f.read()
with (root_dir / "README.rst").open() as f:
    long_description = f.read()
with (root_dir / "requirements.in").open() as f:
    requirements = f.read().splitlines()


setuptools.setup(
    name="occtax",
    version=version,
    description="OccTax",
    long_description=long_description,
    long_description_content_type="text/x-rst",
    maintainer="Parcs nationaux des Écrins et des Cévennes",
    maintainer_email="geonature@ecrins-parcnational.fr",
    url="https://github.com/PnX-SI/GeoNature",
    packages=setuptools.find_packages("backend"),
    package_dir={"": "backend"},
    package_data={"occtax.migrations": ["data/*.sql"]},
    install_requires=requirements,
    entry_points={
        "gn_module": [
            "code = occtax:MODULE_CODE",
            "picto = occtax:MODULE_PICTO",
            "blueprint = occtax.blueprint:blueprint",
            "config_schema = occtax.conf_schema_toml:GnModuleSchemaConf",
            "migrations = occtax:migrations",
        ],
    },
    classifiers=[
        "Development Status :: 1 - Planning",
        "Intended Audience :: Developers",
        "Natural Language :: English",
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: GNU Affero General Public License v3"
        "Operating System :: OS Independent",
    ],
)
