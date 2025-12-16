from marshmallow import Schema, fields


class ValidationRouteSchema(Schema):
    """
    Serialization schema for the /validation route.

    Attributes
    ----------
    id_synthese : fields.Int
        Identifier of the observation in the synthesis
    nom_cite : fields.Str
        Cited name of the species
    observers : fields.Str
        List of observers
    date_min : fields.DateTime
        Minimum observation date
    date_max : fields.DateTime
        Maximum observation date
    id_validation : fields.Int
        Validation identifier
    validation_date : fields.DateTime
        Validation date
    validation_auto : fields.Boolean
        Indicates if the validation is automatic
    validation_comment : fields.Str
        Validation comment
    validator : fields.Str
        Name of the validator
    nomenclature_cd_nomenclature : fields.Str
        Nomenclature code
    nomenclature_mnemonique : fields.Str
        Nomenclature mnemonic
    nomenclature_label_default : fields.Str
        Default label of the nomenclature
    """

    id_synthese = fields.Int()
    nom_cite = fields.Str(allow_none=True)
    observers = fields.Str(allow_none=True)
    date_min = fields.DateTime(allow_none=True)
    date_max = fields.DateTime(allow_none=True)
    id_validation = fields.Int()
    validation_date = fields.DateTime()
    validation_auto = fields.Boolean()
    validation_comment = fields.Str(allow_none=True)
    validator = fields.Str()
    nomenclature_cd_nomenclature = fields.Str()
    nomenclature_mnemonique = fields.Str()
    nomenclature_label_default = fields.Str()
