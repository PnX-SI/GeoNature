from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class CorNomListeTaxonomieModel(db.Model):
    __tablename__ = 'cor_nom_liste'
    __table_args__ = {'schema':'taxonomie'}
    id_liste = db.Column(db.Integer, db.ForeignKey("taxonomie.bib_listes.id_liste"), nullable=False, primary_key=True)
    id_nom = db.Column(db.Integer, db.ForeignKey("taxonomie.bib_noms.id_nom"), nullable=False, primary_key=True)

    def __init__(self, id_liste, id_nom):
        self.id_liste = id_liste
        self.id_nom = id_nom

    def json(self):
        return {'id_liste': self.id_liste, 'id_nom': self.id_nom}

    @classmethod
    def find_by_id(cls, id_nom):
        return cls.query.filter_by(id_nom=id_nom).first()
