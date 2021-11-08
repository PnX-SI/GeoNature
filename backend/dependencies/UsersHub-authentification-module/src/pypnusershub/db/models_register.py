import re
import base64

from flask import current_app
from pypnusershub.db.models import check_and_encrypt_password
from sqlalchemy import or_
from sqlalchemy.dialects.postgresql import JSONB

from .models import User, db as DB


class TempUser(DB.Model):
    __tablename__ = "temp_users"
    __table_args__ = {"schema": "utilisateurs", "extend_existing": True}

    id_temp_user = DB.Column(DB.Integer, primary_key=True)
    token_role = DB.Column(DB.Unicode)
    organisme = DB.Column(DB.Unicode)
    id_application = DB.Column(DB.Integer)
    confirmation_url = DB.Column(DB.Unicode)
    groupe = DB.Column(DB.Boolean)
    identifiant = DB.Column(DB.Unicode)
    nom_role = DB.Column(DB.Unicode)
    prenom_role = DB.Column(DB.Unicode)
    desc_role = DB.Column(DB.Unicode)
    password = DB.Column(DB.Unicode)
    pass_md5 = DB.Column(DB.Unicode)
    email = DB.Column(DB.Unicode)    
    id_organisme = DB.Column(DB.Integer)
    remarques = DB.Column(DB.Unicode)
    champs_addi = DB.Column(JSONB)
    date_insert = DB.Column(DB.DateTime)
    date_update = DB.Column(DB.DateTime)
    
    def set_password(self, password, password_confirmation, md5):
        self.password, self.pass_md5 = check_and_encrypt_password(
            password, password_confirmation, md5
        )

    def is_valid(self):
        is_valid = True
        msg = ""

        if not self.password:
            is_valid = False
            msg += "Password is required. "

        re.compile(r"[^@\s]+@[^@\s]+\.[a-zA-Z0-9]+$")
        if not re.match(r"[^@\s]+@[^@\s]+\.[a-zA-Z0-9]+$", self.email):
            is_valid = False
            msg += "E-mail is not valid. "
        # check if user or temp user exist with an email or login given
        role = (
            DB.session.query(User)
            .filter(or_(User.email == self.email, User.identifiant == self.identifiant))
            .first()
        )
        if role:
            is_valid = False
            if role.email == self.email:
                msg += (
                    f"Un compte avec l'email {self.email} existe déjà. " +
                    "S'il s'agit de votre email, vous pouvez faire une demande de renouvellement " +
                    "de mot de passe via la page de login de GeoNature."
                )
            else:
                msg += (
                    f"Un compte avec l'identifiant {self.identifiant} existe déjà. " +
                    "Veuillez choisir un identifiant différent."
                )

        temp_role = (
            DB.session.query(TempUser)
            .filter(or_(TempUser.email == self.email, TempUser.identifiant == self.identifiant))
            .first()
        )
        if temp_role:
            is_valid = False
            if temp_role.email == self.email:
                msg += (
                    f"Un compte en attente de validation avec l'email {self.email} existe déjà. "+
                    "Merci de patienter le temps que votre demande soit traitée."

                )
            else:
                msg += (
                    "Un compte en attente de validation avec l'identifiant " +
                    f"{self.identifiant} existe déjà. " +
                    "Veuillez choisir un identifiant différent."
                )

        return (is_valid, msg)

    def as_dict(self, recursif=False, columns=(), depth=None):
        """
            The signature of the function must be the as same the as_dict func 
            from https://github.com/PnX-SI/Utils-Flask-SQLAlchemy
        """
        return {
            "id_temp_user": self.id_temp_user,
            "token_role": self.token_role,
            "organisme": self.organisme,
            "id_application": self.id_application,
            "confirmation_url": self.confirmation_url,
            "groupe": self.groupe,
            "identifiant": self.identifiant,
            "nom_role": self.nom_role,
            "prenom_role": self.prenom_role,
            "desc_role": self.desc_role,
            "password": self.password,
            "pass_md5": self.pass_md5,
            "email": self.email,
            "id_organisme": self.id_organisme,
            "remarques": self.remarques,
            "champs_addi": self.champs_addi,
        }


class CorRoleToken(DB.Model):

    __tablename__ = "cor_role_token"
    __table_args__ = {"schema": "utilisateurs", "extend_existing": True}

    id_role = DB.Column(DB.Integer, primary_key=True)
    token = DB.Column(DB.Unicode)

    def as_dict(self, recursif=False, columns=(), depth=None):
        """
            The signature of the function must be the as same the as_dict func 
            from https://github.com/PnX-SI/Utils-Flask-SQLAlchemy
        """
        return {"id_role": self.id_role, "token": self.token}
