from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class RelevesCFauneModel(db.Model):
    __tablename__       = 't_releves_cfaune'
    __table_args__      = {'schema':'contactfaune'}
    id_releve_cfaune    = db.Column(db.BigInteger, primary_key=True)
    id_lot              = db.Column(db.Integer)
    id_numerisateur     = db.Column(db.Integer)
    # datemin             = db.Column(db.Date, nullable=False)
    # datemax             = db.Column(db.Date, nullable=False)
    heureobs            = db.Column(db.Integer)
    insee               = db.Column(db.Text(length='5'))
    altitudemin         = db.Column(db.Integer)
    altitudemax         = db.Column(db.Integer)
    saisie_initiale     = db.Column(db.Text(length='20'))
    supprime            = db.Column(db.BOOLEAN(create_constraint=False))
    # date_update         = db.Column(db.Date, nullable=False)
    commentaire         = db.Column(db.Text)
    id_nomenclature_technique_obervation = db.Column(db.Integer, nullable=False)

    def __init__(self, id_releve_cfaune):
        self.id_releve_cfaune = id_releve_cfaune
    
    def json(self):
        return {column.key: getattr(self, column.key) for column in self.__table__.columns}

    @classmethod
    def find_by_id(cls, id_releve_cfaune):
        return cls.query.filter_by(id_releve_cfaune=id_releve_cfaune).first()