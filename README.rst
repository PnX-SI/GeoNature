GeoNature
=========

Application de synthèse des observations faune et flore.

Elle regroupe toutes les données des différents protocoles FAUNE et FLORE en les limitant au niveau QUI QUOI QUAND OU.

Présentation
-----------

Principe général : Un protocole = Un outil = Une BDD + Une BDD et une application de SYNTHESE regroupant les données des différents protocoles sur la base des champs communs à tous les protocoles (QUI a vu QUOI, OU et QUAND).

.. image :: docs/images/schema-general.jpg

Les données des différents protocoles sont saisies avec des outils différents. Il peut s'agir d'un simple tableur ou couche SIG pour les besoins
simples concernant peu d'utilisateurs comme d'une base Access plus ou moins élaborée ou encore d'une base de données PostGIS
accompagnée d'une interface web lorsque les utilisateurs sont nombreux. Certaines données sont même saisies directement sur le terrain grâce
aux applications et aux outils nomades. Les données sont stockées par protocole, dans des schémas différents. Chaque schéma possède un
modèle de données correspondant strictement au protocole. Il est structuré pour répondre aux besoins spécifiques de ce protocole. On respecte
bien ici le principe UN BESOIN = UN PROTOCOLE = UN MODELE DE DONNEES = UN OUTIL.

Grâce aux REFERENTIELS tels que le taxref pour la taxonomie ou encore les référentiels géographiques de l'IGN, les informations communes à
tous les protocoles peuvent être regroupées dans un schéma de SYNTHESE. En résumé qui a vu quoi, quand, où et comment (le protocole) ? Ce
schéma de synthèse est automatiquement alimenté par des déclencheurs (triggers) au sein de la base de données ou périodiquement grâce à un
outil ETL (Extract Transform and Load) tel que Talend Open Studio pour les données saisies avec d'autres outils tels que des bases de données
fichiers (Access) ou des tableurs.

Le schéma de chacun des protocoles répond donc au besoin du protocole et le schéma de synthèse qui regroupe toutes les données produites
répond lui aux besoins d'agglomération et d'échange des données ainsi qu'au besoin de porter à connaissance. Une vue spécifique est mise en place
sur la base de données de synthèse pour chaque organisme partenaire (SINP, LPO, INPN...). Elles leur permettent d'extraire les données en
temps réel en totale autonomie. 

Pour en savoir plus :  `<docs/pdf/protocoles-locaux-echanges-nationaux.pdf>`_

.. image :: docs/images/capture-application.png

Installation
-----------

Consulter la documentation :  `<http://geonature.rtfd.org>`_

License
-------

* OpenSource - BSD
* Copyright (c) 2014 - Parc National des Écrins - Parc national des Cévennes


.. image:: http://pnecrins.github.io/GeoNature/img/logo-pne.jpg
    :target: http://www.ecrins-parcnational.fr

.. image:: http://pnecrins.github.io/GeoNature/img/logo-pnc.jpg
    :target: http://www.cevennes-parcnational.fr
