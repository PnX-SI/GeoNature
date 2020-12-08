import setuptools
from pathlib import Path


root_dir = Path(__file__).absolute().parent
with (root_dir / 'VERSION').open() as f:
    version = f.read()
with (root_dir / 'README.rst').open() as f:
    long_description = f.read()


setuptools.setup(
    name='geonature',
    description='Application de saisie et de synthèse des observations faune et flore',
    long_description=long_description,
    long_description_content_type='text/x-rst',
    maintainer='Parcs nationaux des Écrins et des Cévennes',
    maintainer_email='geonature@ecrins-parcnational.fr',
    url='https://github.com/PnX-SI/GeoNature/',
    python_requires='>=3.6',
    version=version,
    packages=setuptools.find_packages('backend'),
    package_dir={'': 'backend'},
    install_requires=list(open('backend/requirements.in', 'r')),
    classifiers=[
        "Framework :: Flask",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.6",
    ],
    entry_points={
        'console_scripts': [
            'geonature = geonature.core.command:main',
        ],
    },
)
