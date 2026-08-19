from flask import flash
from flask_admin.contrib.sqla import ModelView
from sqlalchemy import exists, select

from geonature.core.admin.utils import CruvedProtectedMixin
from geonature.core.gn_meta.models.datasets import TDatasets
from geonature.utils.env import DB


class ProductionDatabaseAdmin(CruvedProtectedMixin, ModelView):
    module_code = "METADATA"
    object_code = "PRODUCTION_DATABASE"

    column_list = ("name", "contact")
    column_labels = {
        "name": "Nom",
        "contact": "Contact",
    }
    column_searchable_list = ("name",)
    form_columns = ("name", "contact")
    form_args = {
        "name": {"label": "Nom"},
        "contact": {"label": "Contact", "get_label": "nom_complet"},
    }

    def delete_model(self, model):
        """
        Empêche la suppression d'une base de données de production encore
        référencée par un jeu de données.
        """
        in_use = DB.session.scalar(
            select(exists().where(TDatasets.id_production_database == model.id_production_database))
        )
        if in_use:
            flash(
                f"Impossible de supprimer la base de données de production « {model.name} » "
                "car elle est utilisée par au moins un jeu de données.",
                "error",
            )
            return False
        return super().delete_model(model)
