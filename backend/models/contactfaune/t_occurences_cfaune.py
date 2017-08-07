from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class OccurencesCFauneModel(db.Model):
    __tablename__               = 't_occurences_cfaune'
    __table_args__              = {'schema':'contactfaune'}
    id_occurence_cfaune         = db.Column(db.BigInteger, primary_key=True)
    id_releve_cfaune            = db.Column(db.BigInteger, db.ForeignKey("contactfaune.t_releves_cfaune.id_releve_cfaune"), nullable=False)
    id_nomenclature_meth_obs    = db.Column(db.Integer, db.ForeignKey("meta.t_nomenclatures.id_nomenclature"), nullable=False)
    id_nomenclature_statut_bio  = db.Column(db.Integer, db.ForeignKey("meta.t_nomenclatures.id_nomenclature"), nullable=False)
    id_valideur                 = db.Column(db.Integer, db.ForeignKey("utilisateurs.t_roles.id_role"), nullable=False)
    determinateur               = db.Column(db.Text)
    cd_nom                      = db.Column(db.Integer, db.ForeignKey("taxonomie.taxref.cd_nom"), nullable=False)
    nom_cite                    = db.Column(db.Text)
    v_taxref                    = db.Column(db.Integer)
    num_prelevement_cfaune      = db.Column(db.Text)
    validition                  = db.Column(db.Integer)
    supprime                    = db.Column(db.BOOLEAN(create_constraint=False))
    date_insert                 = db.Column(db.Date)
    date_update                 = db.Column(db.Date)
    commentaire                 = db.Column(db.Text)

    def __init__(self, id_occurence_cfaune):
        self.id_occurence_cfaune = id_occurence_cfaune
    
    def json(self):
        return {column.key: getattr(self, column.key) if not isinstance(column.type, db.Date) else str(getattr(self, column.key)) for column in self.__table__.columns }

    @classmethod
    def find_by_id(cls, id_occurence_cfaune):
        return cls.query.filter_by(id_occurence_cfaune=id_occurence_cfaune).first()