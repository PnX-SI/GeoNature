from flask import current_app
from werkzeug.exceptions import Forbidden, NotFound
from sqlalchemy import func, select, join, and_
from sqlalchemy.orm import joinedload, lazyload, selectinload, contains_eager

from sqlalchemy.orm import aliased, with_expression
from sqlalchemy.exc import NoResultFound

from geonature.utils.env import db
from geonature.core.gn_synthese.schemas import SyntheseSchema
from geonature.core.gn_synthese.models import (
    CorAreaSynthese,
    Synthese,
    TReport,
)
from geonature.core.gn_synthese.utils.blurring import split_blurring_precise_permissions
from geonature.core.gn_permissions.decorators import permissions_required
from geonature.core.sensitivity.models import cor_sensitivity_area_type

from ref_geo.models import LAreas, BibAreasTypes


@permissions_required("R", module_code="SYNTHESE")
def observation(id_synthese, permissions):
    """Get one synthese record for web app with all decoded nomenclature"""
    synthese_query = Synthese.join_nomenclatures().options(
        joinedload("dataset").options(
            selectinload("acquisition_framework").options(
                joinedload("creator"),
                joinedload("nomenclature_territorial_level"),
                joinedload("nomenclature_financing_type"),
            ),
        ),
        # Used to check the sensitivity after
        joinedload("nomenclature_sensitivity"),
    )
    ##################

    fields = [
        "dataset",
        "dataset.acquisition_framework",
        "dataset.acquisition_framework.bibliographical_references",
        "dataset.acquisition_framework.cor_af_actor",
        "dataset.acquisition_framework.cor_objectifs",
        "dataset.acquisition_framework.cor_territories",
        "dataset.acquisition_framework.cor_volets_sinp",
        "dataset.acquisition_framework.creator",
        "dataset.acquisition_framework.nomenclature_territorial_level",
        "dataset.acquisition_framework.nomenclature_financing_type",
        "dataset.cor_dataset_actor",
        "dataset.cor_dataset_actor.role",
        "dataset.cor_dataset_actor.organism",
        "dataset.cor_territories",
        "dataset.nomenclature_source_status",
        "dataset.nomenclature_resource_type",
        "dataset.nomenclature_dataset_objectif",
        "dataset.nomenclature_data_type",
        "dataset.nomenclature_data_origin",
        "dataset.nomenclature_collecting_method",
        "dataset.creator",
        "dataset.modules",
        "validations",
        "validations.validation_label",
        "validations.validator_role",
        "cor_observers",
        "cor_observers.organisme",
        "source",
        "habitat",
        "medias",
        "areas",
        "areas.area_type",
    ]

    # get reports info only if activated by admin config
    if "SYNTHESE" in current_app.config["SYNTHESE"]["ALERT_MODULES"]:
        fields.append("reports.report_type.type")
        synthese_query = synthese_query.options(
            lazyload(Synthese.reports).joinedload(TReport.report_type)
        )

    try:
        synthese = (
            db.session.execute(synthese_query.filter_by(id_synthese=id_synthese))
            .unique()
            .scalar_one()
        )
    except NoResultFound:
        raise NotFound()
    if not synthese.has_instance_permission(permissions=permissions):
        raise Forbidden()

    _, precise_permissions = split_blurring_precise_permissions(permissions)

    # If blurring permissions and obs sensitive.
    if (
        not synthese.has_instance_permission(precise_permissions)
        and synthese.nomenclature_sensitivity.cd_nomenclature != "0"
    ):
        # Use a cte to have the areas associated with the current id_synthese
        cte = select(CorAreaSynthese).where(CorAreaSynthese.id_synthese == id_synthese).cte()
        # Blurred area of the observation
        BlurredObsArea = aliased(LAreas)
        # Blurred area type of the observation
        BlurredObsAreaType = aliased(BibAreasTypes)
        # Types "larger" or equal in area hierarchy size that the blurred area type
        BlurredAreaTypes = aliased(BibAreasTypes)
        # Areas associates with the BlurredAreaTypes
        BlurredAreas = aliased(LAreas)

        # Inner join that retrieve the blurred area of the obs and the bigger areas
        # used for "Zonages" in Synthese. Need to have size_hierarchy from ref_geo
        inner = (
            join(CorAreaSynthese, BlurredObsArea)
            .join(BlurredObsAreaType)
            .join(
                cor_sensitivity_area_type,
                cor_sensitivity_area_type.c.id_area_type == BlurredObsAreaType.id_type,
            )
            .join(
                BlurredAreaTypes,
                BlurredAreaTypes.size_hierarchy >= BlurredObsAreaType.size_hierarchy,
            )
            .join(BlurredAreas, BlurredAreaTypes.id_type == BlurredAreas.id_type)
            .join(cte, cte.c.id_area == BlurredAreas.id_area)
        )

        # Outer join to join CorAreaSynthese taking into account the sensitivity
        outer = (
            inner,
            and_(
                Synthese.id_synthese == CorAreaSynthese.id_synthese,
                Synthese.id_nomenclature_sensitivity
                == cor_sensitivity_area_type.c.id_nomenclature_sensitivity,
            ),
        )

        synthese_query = (
            synthese_query.outerjoin(*outer)
            # contains_eager: to populate Synthese.areas directly
            .options(contains_eager(Synthese.areas.of_type(BlurredAreas)))
            .options(
                with_expression(
                    Synthese.the_geom_authorized,
                    func.coalesce(BlurredObsArea.geom_4326, Synthese.the_geom_4326),
                )
            )
            .order_by(BlurredAreaTypes.size_hierarchy)
        )
    else:
        synthese_query = synthese_query.options(
            lazyload("areas").options(
                joinedload("area_type"),
            ),
            with_expression(Synthese.the_geom_authorized, Synthese.the_geom_4326),
        )

    synthese = (
        db.session.execute(synthese_query.filter(Synthese.id_synthese == id_synthese))
        .unique()
        .scalar_one()
    )

    synthese_schema = SyntheseSchema(
        only=Synthese.nomenclature_fields + fields,
        exclude=["areas.geom"],
        as_geojson=True,
        feature_geometry="the_geom_authorized",
    )
    return synthese_schema.dump(synthese)
