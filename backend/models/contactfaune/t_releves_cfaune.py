from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class RelevesCFauneModel(db.Model):
    __tablename__ = 't_releves_cfaune'
    __table_args__ = {'schema':'contactfaune'}