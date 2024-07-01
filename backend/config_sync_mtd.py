from geonature.core.gn_meta.mtd import (
    INPNCAS,
    sync_af_and_ds as mtd_sync_af_and_ds,
    sync_af_and_ds_by_user,
)
from geonature.core.gn_meta.routes import routes
from flask import request, g
import logging

INPNCAS.base_url = "https://inpn.mnhn.fr/authentication/"
INPNCAS.user = "user_change"
INPNCAS.password = "pass_change"
INPNCAS.id_instance_filter = 6
INPNCAS.mtd_api_endpoint = "https://preprod-inpn.mnhn.fr/mtd"
INPNCAS.activated = True

log = logging.getLogger()


@routes.before_request
def synchronize_mtd():
    from flask_login import current_user

    if request.endpoint in ["gn_meta.get_datasets", "gn_meta.get_acquisition_frameworks_list"]:
        try:
            sync_af_and_ds_by_user(id_role=current_user.id_role)
        except Exception as e:
            log.exception("Error while get JDD via MTD")
