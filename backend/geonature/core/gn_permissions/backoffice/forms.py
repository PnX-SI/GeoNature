from flask_wtf import FlaskForm


from wtforms import StringField, PasswordField, BooleanField, SubmitField, HiddenField, SelectField, RadioField,SelectMultipleField, widgets, Form
from wtforms.validators import DataRequired, Email

from geonature.core.gn_permissions.models import TFilters, BibFiltersType
from geonature.utils.env import DB



class CruvedScopeForm(FlaskForm):
    """
    Forms to manage cruved scope permissions
    """
    C = RadioField('create_scope')
    R = RadioField('read_scope')
    U = RadioField('update_scope')
    V = RadioField('validate_scope')
    E = RadioField('edit_scope')
    D = RadioField('delete_scope')
    submit = SubmitField('Valider')

    def init_choices(self):
        """
            Get and set the scope filters to the form choices
        """
        data = DB.session.query(TFilters.id_filter, TFilters.description_filter).join(
            BibFiltersType,BibFiltersType.id_filter_type == TFilters.id_filter_type
        ).filter(
            BibFiltersType.code_filter_type == 'SCOPE'
        ).all() 
        scope_choices = [(str(code), value) for code,value in data]
        self.C.choices = scope_choices
        self.R.choices = scope_choices
        self.U.choices = scope_choices
        self.V.choices = scope_choices
        self.E.choices = scope_choices
        self.D.choices = scope_choices
    
    def __init__(self, *args, **kwargs):
        super(CruvedScopeForm, self).__init__(*args, **kwargs)
        print('LAAAAAAAAA')
        self.init_choices()
        print(self.C.choices)
        
