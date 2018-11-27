from flask_wtf import FlaskForm


from wtforms import StringField, PasswordField, BooleanField, SubmitField, HiddenField, SelectField, RadioField,SelectMultipleField, widgets, Form
from wtforms.validators import DataRequired, Email

class CruvedScope(FlaskForm):
    """
    Forms to manage cruved scope permissions
    """
    create_scope = RadioField('create_scope', choices=[('la','li')])
    read_scope = RadioField('read_scope')
    update_scope = RadioField('update_scope')
    validate_scope = RadioField('validate_scope')
    export_scope = RadioField('edit_scope')
    delete_scope = RadioField('delete_scope')
