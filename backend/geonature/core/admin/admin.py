from flask import current_app
from flask_admin import Admin

from pypnnomenclature.admin import (
    BibNomenclaturesTypesAdminConfig,
    BibNomenclaturesTypesAdmin,
    TNomenclaturesAdminConfig,
    TNomenclaturesAdmin,
)

admin = Admin(
    current_app,
    name="Backoffice d'administration de GeoNature",
    template_mode="bootstrap3",
    url="/admin",
)

admin.add_view(
    BibNomenclaturesTypesAdminConfig(
        BibNomenclaturesTypesAdmin, DB.session, name="Type de nomenclatures"
    ),
    category="Nomenclatures",
)

admin.add_view(
    TNomenclaturesAdminConfig(
        TNomenclaturesAdmin, DB.session, name="Items de nomenclatures"
    ),
    category="Nomenclatures",
)
