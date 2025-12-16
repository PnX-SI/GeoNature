from flask import current_app
from geonature.core.notifications.utils import dispatch_notifications


def notify_validation_state_change(synthese, validation, status):
    """
    Sends a notification to the recorder when the validation status changes.

    This function dispatches a notification to the observation's recorder to
    inform them of the validation status change. The notification contains a
    link to the observation in the interface.

    Parameters
    ----------
    synthese : Synthese
        Synthesis observation object concerned by the validation
    validation : TValidations
        Validation object created
    status : TNomenclatures
        Nomenclature object of the validation status applied

    Notes
    -----
    - No notification is sent if the observation has no recorder (id_digitiser)
    - The notification uses the dispatch system with category "VALIDATION-STATUS-CHANGED%"
    - The notification context includes the synthese, validation, and status objects
    - The notification URL points to the observation detail page

    Examples
    --------
    >>> notify_validation_state_change(obs, valid, status_nom)
    # Sends a notification to the user obs.id_digitiser
    """
    if not synthese.id_digitiser:
        return

    dispatch_notifications(
        code_categories=["VALIDATION-STATUS-CHANGED%"],
        id_roles=[synthese.id_digitiser],
        title="Validation status change",
        url=(
            f"{current_app.config['URL_APPLICATION']}"
            f"/#/synthese/occurrence/{synthese.id_synthese}"
        ),
        context={
            "synthese": synthese,
            "validation": validation,
            "status": status,
        },
    )
