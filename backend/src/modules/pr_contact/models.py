
# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import ForeignKey
from sqlalchemy.sql import select, func
from sqlalchemy.orm import relationship
from ...utils.utilssqlalchemy import serializableModel, serializableGeoModel

from sqlalchemy.dialects.postgresql import UUID

from ...core.users.models import TRoles
from pypnnomenclature.models import TNomenclatures
from src.core.ref_geo.models import LAreasWithoutGeom

from geoalchemy2 import Geometry

db = SQLAlchemy()


corRoleRelevesContact = db.Table('cor_role_releves_contact',db.MetaData(schema='pr_contact'),
    db.Column('id_releve_contact', db.Integer, ForeignKey('pr_contact.t_releves_contact.id_releve_contact'), primary_key=True),
    db.Column('id_role', db.Integer, ForeignKey('utilisateurs.t_roles.id_role'), primary_key=True)
)

corMunicipalityRelevesContact = db.Table('cor_municipality_releves_contact',db.MetaData(schema='pr_contact'),
    db.Column('id_releve_contact', db.Integer, ForeignKey('pr_contact.t_releves_contact.id_releve_contact'), primary_key=True),
    db.Column('id_area', db.Integer, ForeignKey('ref_geo.l_areas.id_area'), primary_key=True)
)


class TRelevesContact(serializableGeoModel):
    __tablename__ = 't_releves_contact'
    __table_args__ = {'schema':'pr_contact'}
    id_releve_contact = db.Column(db.Integer, primary_key=True)
    id_dataset = db.Column(db.Integer)
    id_digitiser = db.Column(db.Integer, ForeignKey('utilisateurs.t_roles.id_role'))
    date_min = db.Column(db.DateTime)
    date_max = db.Column(db.DateTime)
    altitude_min = db.Column(db.Integer)
    altitude_max = db.Column(db.Integer)
    meta_device_entry = db.Column(db.Unicode)
    deleted = db.Column(db.Boolean, default=False)
    meta_create_date = db.Column(db.DateTime)
    meta_update_date = db.Column(db.DateTime)
    comment = db.Column(db.Unicode)
    geom_local = db.Column(Geometry)
    geom_4326 = db.Column(Geometry('GEOMETRY', 4326))

    t_occurrences_contact = relationship("TOccurrencesContact", lazy='joined' , cascade="all, delete-orphan")

    observers = db.relationship(
        'TRoles',
        secondary=corRoleRelevesContact,
        primaryjoin=(corRoleRelevesContact.c.id_releve_contact == id_releve_contact),
        secondaryjoin=(corRoleRelevesContact.c.id_role == TRoles.id_role),
        foreign_keys =[corRoleRelevesContact.c.id_releve_contact,corRoleRelevesContact.c.id_role]
    )
    municipalities = db.relationship(
        'LAreasWithoutGeom',
        secondary=corMunicipalityRelevesContact,
        primaryjoin=(corMunicipalityRelevesContact.c.id_releve_contact == id_releve_contact),
        secondaryjoin=(corMunicipalityRelevesContact.c.id_area == LAreasWithoutGeom.id_area),
        foreign_keys =[corMunicipalityRelevesContact.c.id_releve_contact,corMunicipalityRelevesContact.c.id_area]
    )

    digitiser = relationship("TRoles", foreign_keys=[id_digitiser])

    def get_geofeature(self, recursif=True):
        return self.as_geofeature('geom_4326', 'id_releve_contact', recursif)


class TOccurrencesContact(serializableModel):
    __tablename__ = 't_occurrences_contact'
    __table_args__ = {'schema':'pr_contact'}
    id_occurrence_contact = db.Column(db.Integer, primary_key=True)
    id_releve_contact = db.Column(db.Integer, ForeignKey('pr_contact.t_releves_contact.id_releve_contact'))
    id_nomenclature_obs_technique = db.Column(db.Integer)
    id_nomenclature_obs_meth = db.Column(db.Integer)
    id_nomenclature_bio_condition = db.Column(db.Integer)
    id_nomenclature_bio_status = db.Column(db.Integer)
    id_nomenclature_naturalness = db.Column(db.Integer)
    id_nomenclature_exist_proof = db.Column(db.Integer)
    id_nomenclature_valid_status = db.Column(db.Integer)
    id_nomenclature_diffusion_level = db.Column(db.Integer)
    id_validator = db.Column(db.Integer)
    determiner = db.Column(db.Unicode)
    determination_method = db.Column(db.Unicode)
    cd_nom = db.Column(db.Integer)
    nom_cite = db.Column(db.Unicode)
    meta_v_taxref = db.Column(db.Unicode, default=select([func.get_default_parameter('taxref_version','NULL')]))
    sample_number_proof = db.Column(db.Unicode)
    digital_proof = db.Column(db.Unicode)
    non_digital_proof = db.Column(db.Unicode)
    deleted = db.Column(db.Boolean)
    meta_create_date = db.Column(db.DateTime)
    meta_update_date = db.Column(db.DateTime)
    comment = db.Column(db.Unicode)

    cor_counting_contact = relationship("CorCountingContact", lazy='joined',  cascade="all, delete-orphan")

class CorCountingContact(serializableModel):
    __tablename__ = 'cor_counting_contact'
    __table_args__ = {'schema':'pr_contact'}
    id_counting_contact = db.Column(db.Integer, primary_key=True)
    id_occurrence_contact = db.Column(db.Integer, ForeignKey('pr_contact.t_occurrences_contact.id_occurrence_contact'))
    id_nomenclature_life_stage = db.Column(db.Integer)
    id_nomenclature_sex = db.Column(db.Integer)
    id_nomenclature_obj_count = db.Column(db.Integer)
    id_nomenclature_type_count = db.Column(db.Integer)
    count_min = db.Column(db.Integer)
    count_max = db.Column(db.Integer)
    unique_id_sinp = db.Column(UUID(as_uuid=True), default=select([func.uuid_generate_v4()]))


class VReleveContact(serializableGeoModel):
    __tablename__ = 'v_releve_contact'
    __table_args__ = {'schema':'pr_contact'}
    id_releve_contact = db.Column(db.Integer)
    id_dataset = db.Column(db.Integer)
    id_digitiser = db.Column(db.Integer)
    date_min = db.Column(db.DateTime)
    date_max = db.Column(db.DateTime)
    altitude_min = db.Column(db.Integer)
    altitude_max = db.Column(db.Integer)
    meta_device_entry = db.Column(db.Unicode)
    deleted = db.Column(db.Boolean, default=False)
    meta_create_date = db.Column(db.DateTime)
    meta_update_date = db.Column(db.DateTime)
    comment = db.Column(db.Unicode)
    geom_4326 = db.Column(Geometry('GEOMETRY', 4326))
    id_occurrence_contact = db.Column(db.Integer, primary_key=True)
    cd_nom = db.Column(db.Integer)
    nom_cite = db.Column(db.Unicode)
    occ_deleted = db.Column(db.Boolean)
    occ_meta_create_date = db.Column(db.DateTime)
    occ_meta_update_date = db.Column(db.DateTime)
    lb_nom = db.Column(db.Unicode)
    nom_valide = db.Column(db.Unicode)
    nom_vern = db.Column(db.Unicode)
    leaflet_popup = db.Column(db.Unicode)
    observateurs = db.Column(db.Unicode)

    def get_geofeature(self, recursif=True):
        return self.as_geofeature('geom_4326', 'id_occurrence_contact', recursif)
