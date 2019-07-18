from flask import current_app
from flask_admin import Admin

admin = Admin(
    current_app,
    name="Backoffice d'administration de GeoNature",
    template_mode="bootstrap3",
    url="/admin",
)
