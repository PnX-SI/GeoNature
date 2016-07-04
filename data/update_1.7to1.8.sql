-- Unicité du cd_nom dans bib_taxons afin d'éviter les doublons. 
-- Si vous avez des doublons, la table bib_taxons ainsi qu'éventuellement vos données doivent être nettoyées.
ALTER TABLE taxonomie.bib_taxons ADD CONSTRAINT unique_cd_nom UNIQUE (cd_nom);