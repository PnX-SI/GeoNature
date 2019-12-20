# nomenclatures fields
counting_nomenclatures = [
    "id_nomenclature_life_stage",
    "id_nomenclature_sex",
    "id_nomenclature_obj_count",
    "id_nomenclature_type_count",
    "id_nomenclature_valid_status",
]

occ_nomenclatures = [
    "id_nomenclature_obs_meth",
    "id_nomenclature_bio_condition",
    "id_nomenclature_bio_status",
    "id_nomenclature_naturalness",
    "id_nomenclature_exist_proof",
    "id_nomenclature_diffusion_level",
    "id_nomenclature_observation_status",
    "id_nomenclature_blurring",
    "id_nomenclature_determination_method",
]

releve_nomenclatures = ["id_nomenclature_obs_technique", "id_nomenclature_grp_typ"]


def get_nomenclature_filters(params):
    """
        return all the nomenclatures from query paramters
        filters by table
    """
    counting_filters = []
    occurrence_filters = []
    releve_filters = []

    for p in params:
        if p[:2] == "id":
            if p in counting_nomenclatures:
                counting_filters.append(p)
            elif p in occ_nomenclatures:
                occurrence_filters.append(p)
            elif p in releve_nomenclatures:
                releve_filters.append(p)
    return releve_filters, occurrence_filters, counting_filters


def is_already_joined(my_class, query):
    """
    Check if the given class is already present is the current query
    _class: SQLAlchemy class
    query: SQLAlchemy query
    return boolean
    """
    return my_class in [mapper.class_ for mapper in query._join_entities]

