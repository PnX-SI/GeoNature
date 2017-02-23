============================
MISE A JOUR DE L'APPLICATION
============================

Les différentes versions sont disponibles sur le Github du projet (https://github.com/PnEcrins/GeoNature/releases).

* Télécharger et extraire la version souhaitée dans un répertoire séparé (où ``X.Y.Z`` est à remplacer par le numéro de la version que vous installez). 
 
  ::  
  
        cd /home/synthese/
        wget https://github.com/PnEcrins/GeoNature/archive/X.Y.Z.zip
        unzip X.Y.Z.zip
        mv geonature geonature_old
        mv GeoNature-X.Y.Z/ geonature
        rm X.Y.Z.zip

* Copier les anciens fichiers de configuration et les comparer avec les nouveaux. Attention, si de nouveaux paramètres ont été ajoutés, ajoutez les dans ces fichiers.
 
  ::  
  
        cp geonature_old/wms/wms.map geonature/wms/wms.map
        cp geonature_old/web/js/config.js geonature/web/js/config.js
        cp geonature_old/web/js/configmap.js geonature/web/js/configmap.js
        cp geonature_old/lib/sfGeonatureConfig.php geonature/lib/sfGeonatureConfig.php
        cp geonature_old/config/databases.yml geonature/config/databases.yml
        cd geonature
    
    
* Si vous l'avez personnalisé, récupérez votre bandeau de l'application 
 
  ::  
  
        cp ../geonature_old/web/images/bandeau_geonature.jpg web/images/bandeau_geonature.jpg

* Lire attentivement les notes de chaque version si il y a des spécificités (https://github.com/PnEcrins/GeoNature/releases). Suivre ces instructions avant de continuer la mise à jour.
       
* Si vous avez ajouté des protocoles spécifiques dans GeoNature (https://github.com/PnEcrins/GeoNature/issues/54), il vous faut les récupérer dans la nouvelle version. 

Commencez par copier les modules Symfony correspondants dans le répertoire de la nouvelle version de GeoNature. 

Il vous faut ensuite reporter les modifications réalisées dans les parties qui ne sont pas génériques (module Symfony ``bibs``, le fichier de routing, la description de la BDD dans le fichier ``config/doctrine/schema.yml`` et l'appel des JS et CSS dans ``apps/backend/modules/home/config/view.yml``).
