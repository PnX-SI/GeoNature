from sqlalchemy import or_
from werkzeug.exceptions import NotFound

from geonature.utils.env import DB
from geonature.core.gn_meta.models import TDatasets


class ReleveRepository():
    """
        Repository: classe permettant l'acces au données
        d'un modèle de type 'releve'
        """
    def __init__(self, model):
        self.model = model

    def get_one(self, id_releve, info_user):
        """Return one releve
        params:
         - id_releve: integer
         - info_user: TRole object model
        """
        try:
            releve = DB.session.query(self.model).get(id_releve)
        except Exception:
            DB.session.rollback()
            raise
        if releve:
            return releve.get_releve_if_allowed(info_user)

        raise NotFound(
            'The releve "{}" does not exist'.format(id_releve)
        )

    def update(self, releve, info_user):
        """ Update the current releve if allowed
        params:
        - releve: a Releve object model
        - info_user: Trole object model
        """
        releve = releve.get_releve_if_allowed(info_user)
        DB.session.merge(releve)
        DB.session.commit()
        DB.session.rollback()
        return releve

    def delete(self, id_releve, info_user):
        """Delete a releve
        params:
         - id_releve: integer
         - info_user: TRole object model"""

        releve = DB.session.query(self.model).get(id_releve)
        if releve:
            releve = releve.get_releve_if_allowed(info_user)
            DB.session.delete(releve)
            DB.session.commit()
            DB.session.rollback()
            return releve
        raise NotFound('The releve "{}" does not exist'.format(id_releve))

    def filter_query_with_autorization(self, user):
        q = DB.session.query(self.model)
        if user.tag_object_code == '2':
            allowed_datasets = TDatasets.get_user_datasets(user)
            q = q.filter(
                or_(
                    self.model.id_dataset.in_(tuple(allowed_datasets)),
                    self.model.observers.any(id_role=user.id_role),
                    self.model.id_digitiser == user.id_role
                )
            )
        elif user.tag_object_code == '1':
            q = q.filter(
                or_(
                    self.model.observers.any(id_role=user.id_role),
                    self.model.id_digitiser == user.id_role
                )
            )
        return q

    def get_all(self, info_user):
        """
            Return all the data from Releve model filtered with
            the cruved authorization
        """
        q = self.filter_query_with_autorization(info_user)
        data = q.all()
        if data:
            return data
        raise NotFound('No releve found')

    def get_filtered_query(self, info_user):
        """
            Return a query object already filtered with
            the cruved authorization
        """
        return self.filter_query_with_autorization(info_user)
