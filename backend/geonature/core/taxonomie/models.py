from utils_flask_sqla.serializers import serializable

from geonature.utils.env import DB

from apptax.taxonomie.models import (
    TaxrefProtectionArticles,
    Taxref,
    CorTaxonAttribut,
    VMTaxrefListForautocomplete,
    BibListes,
)


@serializable
class TaxrefProtectionEspeces(DB.Model):
    __tablename__ = "taxref_protection_especes"
    __table_args__ = {"schema": "taxonomie"}
    cd_nom = DB.Column(DB.Unicode, primary_key=True)
    cd_protection = DB.Column(DB.Unicode, primary_key=True)
    nom_cite = DB.Column(DB.Unicode)
    syn_cite = DB.Column(DB.Unicode)
    nom_francais_cite = DB.Column(DB.Unicode)
    precisions = DB.Column(DB.Unicode)
    cd_nom_cite = DB.Column(DB.Unicode, primary_key=True)


class TaxrefLR(DB.Model):
    __tablename__ = "taxref_liste_rouge_fr"
    __table_args__ = {"schema": "taxonomie"}
    id_lr = DB.Column(DB.Integer, primary_key=True)
    ordre_statut = DB.Column(DB.Integer)
    vide = DB.Column(DB.Unicode)
    cd_nom = DB.Column(DB.Integer)
    cd_ref = DB.Column(DB.Integer)
    nomcite = DB.Column(DB.Unicode)
    nom_scientifique = DB.Column(DB.Unicode)
    auteur = DB.Column(DB.Unicode)
    nom_vernaculaire = DB.Column(DB.Unicode)
    nom_commun = DB.Column(DB.Unicode)
    rang = DB.Column(DB.Unicode)
    famille = DB.Column(DB.Unicode)
    endemisme = DB.Column(DB.Unicode)
    population = DB.Column(DB.Unicode)
    commentaire = DB.Column(DB.Unicode)
    id_categorie_france = DB.Column(DB.Unicode)
    criteres_france = DB.Column(DB.Unicode)
    liste_rouge = DB.Column(DB.Unicode)
    fiche_espece = DB.Column(DB.Unicode)
    tendance = DB.Column(DB.Unicode)
    liste_rouge_source = DB.Column(DB.Unicode)
    annee_publication = DB.Column(DB.Unicode)
    categorie_lr_europe = DB.Column(DB.Unicode)
    categorie_lr_mondiale = DB.Column(DB.Unicode)
