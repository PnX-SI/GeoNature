from sqlalchemy import ForeignKey
from sqlalchemy.sql import select

from geonature.utils.utilssqlalchemy import serializable
from geonature.utils.env import DB


@serializable
class VSynthese(DB.Model):
    __tablename__ = "vm_synthese"
    __table_args__ = {"schema": "gn_dashboard"}
    id_synthese = DB.Column(DB.Unicode, primary_key=True)
    id_source = DB.Column(DB.Unicode)
    id_dataset = DB.Column(DB.Unicode)
    id_nomenclature_obj_count = DB.Column(DB.Unicode)
    count_min = DB.Column(DB.Integer)
    count_max = DB.Column(DB.Integer)
    cd_nom = DB.Column(DB.Unicode)
    cd_ref = DB.Column(DB.Unicode)
    nom_cite = DB.Column(DB.Unicode)
    id_statut = DB.Column(DB.Unicode)
    id_rang = DB.Column(DB.Unicode)
    regne = DB.Column(DB.Unicode)
    phylum = DB.Column(DB.Unicode)
    classe = DB.Column(DB.Unicode)
    ordre = DB.Column(DB.Unicode)
    famille = DB.Column(DB.Unicode)
    lb_nom = DB.Column(DB.Unicode)
    nom_vern = DB.Column(DB.Unicode)
    group1_inpn = DB.Column(DB.Unicode)
    group2_inpn = DB.Column(DB.Unicode)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    lon = DB.Column(DB.Unicode)
    lat = DB.Column(DB.Unicode)
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)

@serializable
class VSyntheseCommunes(DB.Model):
    __tablename__ = "vm_synthese_communes"
    __table_args__ = {"schema": "gn_dashboard"}
    area_name = DB.Column(DB.Unicode, primary_key=True)
    geom_area_4326 = DB.Column(DB.Unicode)
    # id_type = DB.Column(DB.Unicode)
    year = DB.Column(DB.Integer)
    nb_obs = DB.Column(DB.Integer)
    nb_taxons = DB.Column(DB.Integer)
    regne = DB.Column(DB.Unicode)
    phylum = DB.Column(DB.Unicode)
    classe = DB.Column(DB.Unicode)
    # ordre = DB.Column(DB.Unicode)
    # famille = DB.Column(DB.Unicode)

@serializable
class VSyntheseCommunesINPN(DB.Model):
    __tablename__ = "vm_synthese_communes_inpn"
    __table_args__ = {"schema": "gn_dashboard"}
    area_name = DB.Column(DB.Unicode, primary_key=True)
    geom_area_4326 = DB.Column(DB.Unicode)
    year = DB.Column(DB.Integer)
    nb_obs = DB.Column(DB.Integer)
    nb_taxons = DB.Column(DB.Integer)    
    group1_inpn = DB.Column(DB.Unicode)
    group2_inpn = DB.Column(DB.Unicode)

@serializable
class VTaxonomie(DB.Model):
    __tablename__ = "vm_taxonomie"
    __table_args__ = {"schema": "gn_dashboard"}
    level = DB.Column(DB.Unicode, primary_key=True)
    name_taxon = DB.Column(DB.Unicode, primary_key=True)


