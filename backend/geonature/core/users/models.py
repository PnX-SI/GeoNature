from typing import Optional

from sqlalchemy import ForeignKey, Integer, Unicode
from sqlalchemy.orm import Mapped, mapped_column
from pypnusershub.db.models import User
from utils_flask_sqla.serializers import serializable
from geonature.utils.env import db


@serializable
class VUserslistForallMenu(db.Model):
    __tablename__ = "v_userslist_forall_menu"
    __table_args__ = {"schema": "utilisateurs"}
    id_role: Mapped[int] = mapped_column(Integer, primary_key=True)
    nom_role: Mapped[Optional[str]] = mapped_column(Unicode)
    prenom_role: Mapped[Optional[str]] = mapped_column(Unicode)
    nom_complet: Mapped[Optional[str]] = mapped_column(Unicode)
    id_menu: Mapped[int] = mapped_column(Integer, primary_key=True)


@serializable
class CorRole(db.Model):
    __tablename__ = "cor_roles"
    __table_args__ = {"schema": "utilisateurs", "extend_existing": True}
    id_role_groupe: Mapped[int] = mapped_column(
        Integer, ForeignKey("utilisateurs.t_roles.id_role"), primary_key=True
    )
    id_role_utilisateur: Mapped[int] = mapped_column(Integer, primary_key=True)
    role = db.relationship(
        User,
        primaryjoin=(User.id_role == id_role_groupe),
        foreign_keys=[id_role_groupe],
    )

    def __init__(self, id_group, id_role):
        self.id_role_groupe = id_group
        self.id_role_utilisateur = id_role


@serializable
class TApplications(db.Model):
    __tablename__ = "t_applications"
    __table_args__ = {"schema": "utilisateurs", "extend_existing": True}
    id_application: Mapped[int] = mapped_column(Integer, primary_key=True)
    nom_application: Mapped[Optional[str]] = mapped_column(Unicode)
    desc_application: Mapped[Optional[str]] = mapped_column(Unicode)
    id_parent: Mapped[Optional[int]]
