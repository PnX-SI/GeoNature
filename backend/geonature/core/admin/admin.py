from flask import current_app
from flask_admin import Admin, AdminIndexView, expose
from geonature.utils.env import DB

from pypnnomenclature.admin import (
    BibNomenclaturesTypesAdminConfig,
    BibNomenclaturesTypesAdmin,
    TNomenclaturesAdminConfig,
    TNomenclaturesAdmin,
)


# class MyHomeView(AdminIndexView):
#     @expose("/")
#     def index(self):
#         arg1 = "Hello"
#         return self.render("myhome.html")


admin = Admin(
    current_app,
    name="Backoffice d'administration de GeoNature",
    template_mode="bootstrap3",
    url="/admin",
    index_view=AdminIndexView(name="Home", template="admin_home.html", url="/admin"),
)

admin.add_view(
    BibNomenclaturesTypesAdminConfig(
        BibNomenclaturesTypesAdmin,
        DB.session,
        name="Type de nomenclatures",
        category="Nomenclatures",
    )
)

admin.add_view(
    TNomenclaturesAdminConfig(
        TNomenclaturesAdmin,
        DB.session,
        name="Items de nomenclatures",
        category="Nomenclatures",
    )
)
