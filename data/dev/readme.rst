
AVERTISSEMENT
=============

Les scripts fournis ici sont destinés au developpement. Ils permettent d'insérer un jeu de données dans la base de données de dev.
Des `TRUNCATE CASCADE` sont réalisés sur les tables, vous devez donc évaluer si des données importantes risquent ou non d'être effacées de votre base.


Insertion des données taxonomiques
----------------------------------
::

    sudo su postgres
    psql -h localhost -d geonature2db -U geonatuser -f "/home/myuser/geonature/data/dev/jdd_taxo_dev.sql"


Insertion des données de synthèse
----------------------------------

::

    psql -h localhost -d geonature2db -U geonatuser -f "/home/myuser/geonature/data/dev/jdd_synthese_dev.sql"
    exit
