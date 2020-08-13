from flask import current_app

from sqlalchemy.exc import IntegrityError

from geonature.utils.env import DB
from geonature.core.gn_commons.models import TMedias, BibTablesLocation
from geonature.core.gn_commons.file_manager import (
    upload_file, remove_file,
    rename_file
)

import datetime

class TMediaRepository():
    '''
        Reposity permettant de manipuler un objet média
        au niveau de la base de données et du système de fichier
        de façon synchrone
    '''
    media_data = dict()
    data = dict()
    file = None
    media = None
    new = False

    def __init__(self, data=None, file=None, id_media=None):
        self.data = data or {}
    
        # filtrer les données du dict qui
        # vont être insérées dans l'objet Model
        self.media_data = {
            k: self.data[k] for k in TMedias.__mapper__.c.keys() if k in self.data
        }
        self.file = file

        # Chargement du média
        if self.media_data.get('id_media'):
            self.media = self._load_from_id(self.media_data['id_media'])
        elif id_media is not None:
            self.media = self._load_from_id(id_media)
        else:
            self.new = True
            self.media = TMedias(**self.media_data)

    def create_or_update_media(self):
        '''
            Création ou modification d'un média :
             - Enregistrement en base de données
             - Stockage du fichier
        '''
        if self.new:
            try:
                self._persist_media_db()
            except Exception as e:
                raise e

        # Si le média à un fichier associé
        if self.file:
            self.data['isFile'] = True
            self.media_data['media_path'] = self.upload_file()
            self.media_data['media_url'] = None
        elif self.data.get('media_path') not in ['', None]:
            self.data['isFile'] = True
            self.media_data['media_url'] = None
        else:
            self.data['isFile'] = False
            self.media_data['media_path'] = None
            self.media_data['media_url'] = self.data['media_url']

        # Si le média avait un fichier associé
        # et qu'il a été remplacé par une url
        if (
                (not self.new) and
                (self.data['isFile'] is not True) and
                (self.media.media_path is not None)
        ):
            remove_file(self.media.media_path)


        for k in self.media_data:
            setattr(self.media, k, self.media_data[k])

        self._persist_media_db()

        return self.media

    def _persist_media_db(self):
        '''
            Enregistrement des données dans la base
        '''
        # @TODO récupérer les exceptions
        try:
            DB.session.add(self.media)
            DB.session.commit()
            for k in self.media_data:
                self.media_data[k] = getattr(self.media, k)
        except IntegrityError as exp:
            # @TODO A revoir avec les nouvelles contrainte
            DB.session.rollback()
            if 'check_entity_field_exist' in exp.args[0]:
                raise Exception(
                    "{} doesn't exists".format(self.data['id_table_location'])
                )
            if 'fk_t_medias_check_entity_value' in exp.args[0]:
                raise Exception(
                    "id {} of {} doesn't exists".format(
                        self.data['id_table_location']
                    )
                )
            else:
                raise Exception(
                    "Errors {}".format(
                        exp.args
                    )
                )

    def upload_file(self):
        '''
            Upload des fichiers sur le serveur
        '''
        # @TODO récupérer les exceptions
        filepath = upload_file(
            self.file,
            str(self.media.id_table_location),
            "{id_media}_{file_name}".format(
                id_media=self.media.id_media,
                file_name=self.file.filename
            )
        )
        return filepath

    def delete(self):
        # Note si SQLALCHEMY_TRACK_MODIFICATIONS  = true alors suppression du fichier gérée automatiquement

        # Suppression du média physiquement
        # En réalité renommage
        initial_path = self.media.media_path

        if self.media.media_path and not current_app.config['SQLALCHEMY_TRACK_MODIFICATIONS']:
            print('yakou')
            try:
                self.media.__before_commit_delete__()

            except FileNotFoundError:
                raise Exception('Unable to delete file')

        # Suppression du média dans la base
        try:
            DB.session.delete(self.media)
            DB.session.commit()
        except Exception:
            if initial_path:
                new_path = rename_file(
                    self.media.media_path,
                    initial_path
                )

    def _load_from_id(self, id_media):
        '''
            Charge un média de la base à partir de son identifiant
        '''
        media = DB.session.query(TMedias).get(id_media)
        return media

    


class TMediumRepository():
    '''
        Classe permettant de manipuler des collections
        d'objet média
    '''

    def get_medium_for_entity(entity_uuid):
        '''
            Retourne la liste des médias pour un objet
            en fonction de son uuid
        '''
        medium = DB.session.query(TMedias).filter(
            TMedias.uuid_attached_row == entity_uuid
        ).all()
        return medium
    
    def sync_medias():
        '''
            Met à jour les médias
              - supprime les médias sans uuid_attached_row plus vieux que 24h
              - supprimes les médias dont l'object attaché n'existe plus TODO
        '''


        # delete media temp > 24h
        res_medias_temp = (
            DB.session.query(TMedias.id_media)
            .filter(
                TMedias.meta_update_date < (datetime.datetime.now() - datetime.timedelta(hours=24))
            )
            .all()
        )

        id_medias_temp = [ res.id_media for res in res_medias_temp]

        for id_media in id_medias_temp:
            TMediaRepository(id_media=id_media).delete()


def get_table_location_id(schema_name, table_name):
    print(schema_name, table_name)
    try:
        location = DB.session.query(BibTablesLocation).filter(
            BibTablesLocation.schema_name == schema_name
        ).filter(
            BibTablesLocation.table_name == table_name
        ).one()
    except :
        return None
    return location.id_table_location
