============
INSTALLATION
============

Texte d'intro.

Les auteurs  :ref:`Auteurs <auteurs>`.

Prérequis
---------

* Serveur


Ressources minimum :

* 1 Go RAM
* 10 Go disk space


Installation
------------

Once the OS is installed (basic installation, with OpenSSH server), install
the last version with the following commands :

::

    ma commande
    chmod +x install.sh
    ./install.sh


You will be prompt for editing the base configuration file (``settings.ini``),
using the default editor.

:notes:

    If you leave *localhost* for the database host (``dbhost`` value), a
    Postgresql with PostGis will be installed locally.

    In order to use a remote server (*recommended*), set the appropriate values
    for the connection.
    The connection must be operational (it will be tested during install).


Mise à jour de l'application
----------------------------

Les versions sont publiées sur `la forge Github <https://github.com/PnEcrins/FF-synthese/releases>`_.
Télécharger et extraire l'archive dans un répertoire à part (**recommandé**).

.. code-block:: bash

    wget https://github.com/PnEcrins/FF-synthese/archive/vX.Y.Z.zip
    unzip vX.Y.Z.zip
    cd FF-synthese-X.Y.Z/


Trucs et astuces
----------------
