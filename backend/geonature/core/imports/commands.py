import click

from flask.cli import with_appcontext
import sqlalchemy as sa

from geonature.utils.env import db

from .models import FieldMapping


synthese_fieldmappings = {
    "unique_id_sinp": "uuid_perm_sinp",
    "entity_source_pk_value": "id_synthese",
    "unique_id_sinp_grp": "uuid_perm_grp_sinp",
    "unique_id_sinp_generate": "",
    "meta_create_date": "date_creation",
    "meta_v_taxref": "",
    "meta_update_date": "date_modification",
    "date_min": "date_debut",
    "date_max": "date_fin",
    "hour_min": "heure_debut",
    "hour_max": "heure_fin",
    "altitude_min": "alti_min",
    "altitude_max": "alti_max",
    "depth_min": "prof_min",
    "depth_max": "prof_max",
    "altitudes_generate": "",
    "longitude": "",
    "latitude": "",
    "observers": "observateurs",
    "comment_description": "comment_occurrence",
    "id_nomenclature_info_geo_type": "type_info_geo",
    "id_nomenclature_grp_typ": "type_regroupement",
    "grp_method": "methode_regroupement",
    "nom_cite": "nom_cite",
    "cd_nom": "cd_nom",
    "id_nomenclature_obs_technique": "technique_observation",
    "id_nomenclature_bio_status": "biologique_statut",
    "id_nomenclature_bio_condition": "etat_biologique",
    "id_nomenclature_biogeo_status": "biogeographique_statut",
    "id_nomenclature_behaviour": "comportement",
    "id_nomenclature_naturalness": "naturalite",
    "comment_context": "comment_releve",
    "id_nomenclature_sensitivity": "niveau_sensibilite",
    "id_nomenclature_diffusion_level": "niveau_precision_diffusion",
    "id_nomenclature_blurring": "floutage_dee",
    "id_nomenclature_life_stage": "stade_vie",
    "id_nomenclature_sex": "sexe",
    "id_nomenclature_type_count": "type_denombrement",
    "id_nomenclature_obj_count": "objet_denombrement",
    "count_min": "nombre_min",
    "count_max": "nombre_max",
    "id_nomenclature_determination_method": "methode_determination",
    "determiner": "determinateur",
    "id_digitiser": "",
    "id_nomenclature_exist_proof": "preuve_existante",
    "digital_proof": "preuve_numerique_url",
    "non_digital_proof": "preuve_non_numerique",
    "id_nomenclature_valid_status": "niveau_validation",
    "validator": "validateur",
    "meta_validation_date": "date_validation",
    "validation_comment": "comment_validation",
    "id_nomenclature_geo_object_nature": "nature_objet_geo",
    "id_nomenclature_observation_status": "statut_observation",
    "id_nomenclature_source_status": "statut_source",
    "reference_biblio": "reference_biblio",
    "cd_hab": "cd_habref",
    "WKT": "geometrie_wkt_4326",
    "place_name": "nom_lieu",
    "precision": "precision_geographique",
    "the_geom_point": "",
    "the_geom_local": "",
    "the_geom_4326": "",
    "codecommune": "",
    "codemaille": "",
    "codedepartement": "",
}
dee_fieldmappings = {
    "altitude_max": "altmax",
    "altitude_min": "altmin",
    "cd_nom": "cdnom",
    "codecommune": "cdcom",
    "codedepartement": "cddept",
    "codemaille": "cdm10",
    "count_max": "denombrementmax",
    "count_min": "denombrementmin",
    "WKT": "geometrie",
    "unique_id_sinp": "permid",
    "entity_source_pk_value": "permid",
    "unique_id_sinp_grp": "permidgrp",
    "date_min": "datedebut",
    "date_max": "datefin",
    "id_nomenclature_geo_object_nature": "natobjgeo",
    "nom_cite": "nomcite",
    "id_nomenclature_obj_count": "objdenbr",
    "comment_context": "obsctx",
    "comment_description": "obsdescr",
    "id_nomenclature_obs_meth": "obsmeth",
    "id_nomenclature_bio_condition": "ocetatbio",
    "id_nomenclature_determination_method": "ocmethdet",
    "id_nomenclature_naturalness": "ocnat",
    "id_nomenclature_sex": "ocsex",
    "id_nomenclature_life_stage": "ocstade",
    "id_nomenclature_bio_status": "ocstatbio",
    "id_nomenclature_exist_proof": "preuveoui",
    "non_digital_proof": "Preuvnonum",
    "digital_proof": "Preuvnum",
    "id_nomenclature_observation_status": "statobs",
    "id_nomenclature_source_status": "statsource",
    "id_nomenclature_type_count": "typdenbr",
    "id_nomenclature_grp_typ": "typgrp",
}


@click.command()
@with_appcontext
def fix_mappings():
    for label, values in [
        ("Synthese GeoNature", synthese_fieldmappings),
        ("Format DEE (champs 10 char)", dee_fieldmappings),
    ]:
        mapping = db.session.execute(sa.select(FieldMapping).filter_by(label=label)).scalar_one()
        mapping.values = values
        db.session.commit()
