from flask_wtf import FlaskForm


from wtforms import (
    StringField,
    PasswordField,
    BooleanField,
    SubmitField,
    HiddenField,
    SelectField,
    RadioField,
    SelectMultipleField,
    widgets,
    Form,
)
from wtforms.validators import DataRequired, Email
from wtforms.widgets import TextArea
from wtforms_sqlalchemy.fields import QuerySelectField


from geonature.core.gn_permissions.models import TFilters, BibFiltersType, TActions
from geonature.core.gn_commons.models import TModules
from geonature.utils.env import DB


class CruvedScopeForm(FlaskForm):
    """
    Forms to manage cruved scope permissions
    """

    C = RadioField("create_scope")
    R = RadioField("read_scope")
    U = RadioField("update_scope")
    V = RadioField("validate_scope")
    E = RadioField("edit_scope")
    D = RadioField("delete_scope")
    submit = SubmitField("Valider")

    def init_choices(self):
        """
        Get and set the scope filters to the form choices
        """
        data = (
            DB.session.query(TFilters.id_filter, TFilters.description_filter)
            .join(BibFiltersType, BibFiltersType.id_filter_type == TFilters.id_filter_type)
            .filter(BibFiltersType.code_filter_type == "SCOPE")
            .all()
        )
        scope_choices = [(str(code), value) for code, value in data]
        self.C.choices = scope_choices
        self.R.choices = scope_choices
        self.U.choices = scope_choices
        self.V.choices = scope_choices
        self.E.choices = scope_choices
        self.D.choices = scope_choices

    def __init__(self, *args, **kwargs):
        super(CruvedScopeForm, self).__init__(*args, **kwargs)
        self.init_choices()


class OtherPermissionsForm(FlaskForm):
    module = QuerySelectField(
        "action",
        query_factory=lambda: DB.session.query(TModules.id_module, TModules.module_label)
        .order_by(TModules.module_label)
        .all(),
        get_pk=lambda mod: str(mod.id_module),
        get_label=lambda mod: mod.module_label,
    )
    action = QuerySelectField(
        "action",
        query_factory=lambda: DB.session.query(TActions).all(),
        get_pk=lambda act: act.id_action,
        get_label=lambda act: act.description_action,
    )
    filter = SelectField(
        "filtre",
    )
    submit = SubmitField("Valider")

    def __init__(self, id_filter_type, *args, **kwargs):
        super(OtherPermissionsForm, self).__init__(*args, **kwargs)
        # id_filter_type = args[0]
        self.filter.choices = [
            (str(filt.id_filter), filt.label_filter)
            for filt in DB.session.query(TFilters)
            .filter(TFilters.id_filter_type == id_filter_type)
            .all()
        ]


class FilterForm(FlaskForm):
    label_filter = StringField("Label", validators=[DataRequired()])
    value_filter = StringField("Valeur du filtre", validators=[DataRequired()])
    description_filter = StringField("Description", validators=[DataRequired()], widget=TextArea())
    submit = SubmitField("Valider")
