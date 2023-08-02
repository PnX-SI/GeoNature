import os
from apptax.admin.admin_view import (
    BibListesView,
    TaxrefView,
    TMediasView,
    BibAttributsView,
    BibThemesView,
)
from geonature.utils.env import db

from apptax.admin.admin import adresses
from apptax.taxonomie.models import Taxref, BibListes, TMedias, BibAttributs, BibThemes
from geonature.core.admin.utils import CruvedProtectedMixin


class CruvedProtectedBibListesView(CruvedProtectedMixin, BibListesView):
    module_code = "TAXHUB"
    object_code = "LISTE"
    extra_actions_perm = {".import_cd_nom_view": "C"}


class CruvedProtectedTaxrefView(CruvedProtectedMixin, TaxrefView):
    module_code = "TAXHUB"
    object_code = "TAXON"


class CruvedProtectedTMediasView(CruvedProtectedMixin, TMediasView):
    module_code = "TAXHUB"
    object_code = "TAXON"


class CruvedProtectedBibAttributsView(CruvedProtectedMixin, BibAttributsView):
    module_code = "TAXHUB"
    object_code = "ATTRIBUT"


class CruvedProtectedBibThemes(CruvedProtectedMixin, BibThemesView):
    module_code = "TAXHUB"
    object_code = "THEME"


def load_admin_views(app, admin):
    static_folder = os.path.join(adresses.root_path, "static")

    admin.add_view(
        CruvedProtectedTaxrefView(
            Taxref,
            db.session,
            name="Taxref",
            endpoint="taxons",
            category="TaxHub",
            static_folder=static_folder,
        )
    )
    admin.add_view(
        CruvedProtectedBibListesView(
            BibListes,
            db.session,
            name="Listes",
            category="TaxHub",
            static_folder=static_folder,
        )
    )

    admin.add_view(
        CruvedProtectedBibAttributsView(
            BibAttributs,
            db.session,
            name="Attributs",
            category="TaxHub",
            static_folder=static_folder,
        )
    )
    admin.add_view(
        CruvedProtectedBibThemes(
            BibThemes,
            db.session,
            name="Thèmes",
            category="TaxHub",
            static_folder=static_folder,
        )
    )

    admin.add_view(
        CruvedProtectedTMediasView(
            TMedias,
            db.session,
            name="Médias",
            category="TaxHub",
            static_folder=static_folder,
        )
    )
