# Dans le repertoire de geonature
# Va remplacer tous les fichiers deleted_<fichier_media> par <fichier_media>
# La synchronisation des medias fera le menage à la prochaine action sur les medias depuis geonature (creation / modification / suppression)

find . -type f -wholename './backend/static/medias/*deleted_*' | sed -e 'p;s/deleted_//' | xargs -n2 mv
