'''
   Spécification du schéma toml des paramètres de configurations
'''

from marshmallow import Schema, fields

class MapListConfig(Schema):
    pass



class ReleveFormConfig(Schema):
    observers_txt = fields.Boolean(missing=True)
    date_min = fields.Boolean(missing=True)
    date_max = fields.Boolean(missing=True)
    hour_min = fields.Boolean(missing=True)
    hour_max = fields.Boolean(missing=True)
    altitude_min = fields.Boolean(missing=True)
    altitude_max = fields.Boolean(missing=True)
    obs_technique = fields.Boolean(missing=True)
    group_type = fields.Boolean(missing=True)
    comment = fields.Boolean(missing=True)

class OccurrenceFormConfig(Schema):
      obs_method = fields.Boolean(missing=True)
      bio_condition = fields.Boolean(missing=True)
      bio_status = fields.Boolean(missing=True)
      naturalness = fields.Boolean(missing=True)
      exist_proof = fields.Boolean(missing=True)
      observation_status = fields.Boolean(missing=True)
      diffusion_level = fields.Boolean(missing=True)
      blurring = fields.Boolean(missing=True)
      determiner = fields.Boolean(missing=True)
      determination_method = fields.Boolean(missing=True)
      determination_method_as_text = fields.Boolean(missing=True)
      sample_number_proof = fields.Boolean(missing=True)
      digital_proof = fields.Boolean(missing=True)
      non_digital_proof = fields.Boolean(missing=True)
      digital_proof = fields.Boolean(missing=True)
      source_status = fields.Boolean(missing=True)
      comment = fields.Boolean(missing=True)

class CountingFormConfig(Schema):
      life_stage = fields.Boolean(missing=True)
      sex = fields.Boolean(missing=True)
      obj_count = fields.Boolean(missing=True)
      type_count = fields.Boolean(missing=True)
      count_min = fields.Boolean(missing=True)
      count_max = fields.Boolean(missing=True)
      validation_status = fields.Boolean(missing=True)

class FormConfig(Schema):
    releve = fields.Nested(ReleveFormConfig, missing=dict())
    occurrence = fields.Nested(OccurrenceFormConfig, missing=dict())
    counting = fields.Nested(CountingFormConfig, missing=dict())

default_map_list_conf = [
    { "prop": "taxons", "name": "Taxon" },
    { "prop": "date_min", "name": "Date début" },
    { "prop": "observateurs", "name": "Observateurs" }
  ]

default_columns_export = [
  "permId",
  "statObs",
  "nomCite",
  "dateDebut",
  "dateFin",
  "heureDebut",
  "heureFin",
  "altMax",
  "altMin",
  "cdNom",
  "cdRef",
  "dateDet",
  "comment",
  "dSPublique",
  "statSource",
  "idOrigine",
  "jddId",
  "refBiblio",
  "obsMeth",
  "ocEtatBio",
  "ocNat",
  "ocSex",
  "ocStade",
  "ocBiogeo",
  "ocStatBio",
  "preuveOui",
  "ocMethDet",
  "preuvNum",
  "preuvNoNum",
  "obsCtx",
  "permIdGrp",
  "methGrp",
  "typGrp",
  "denbrMax",
  "denbrMin",
  "objDenbr",
  "typDenbr",
  "obsId",
  "obsNomOrg",
  "detId",
  "detNomOrg",
  "orgGestDat",
  "WKT",
  "natObjGeo"
 ]


class GnModuleSchemaConf(Schema):
    form_fields = fields.Nested(FormConfig, missing=dict())
    export_view_name = fields.String(missing='ViewExportDLB')
    export_geom_columns_name = fields.String(missing="geom_4326")
    export_id_column_name = fields.String(missing="permId")
    export_columns = fields.List(fields.String(), missing=default_columns_export)
    export_srid = fields.Integer(missing=4326)
    digital_proof_validator = fields.Boolean(missing=True)
    releve_map_zoom_level = fields.Integer(missing=6)
    id_taxon_list = fields.Integer(missing=500)
    default_maplist_columns = fields.List(fields.Dict(), missing=default_map_list_conf)
    


