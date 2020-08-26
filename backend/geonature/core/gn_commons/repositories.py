from flask import current_app

from sqlalchemy.exc import IntegrityError

from pypnnomenclature.models import TNomenclatures

from geonature.utils.env import DB
from geonature.core.gn_commons.models import TMedias, BibTablesLocation
from geonature.core.gn_commons.file_manager import (
    upload_file, remove_file,
    rename_file, removeDisallowedFilenameChars
)

from geonature.utils.errors import ConfigError, GNModuleInstallError, GeoNatureError, GeonatureApiError


import pathlib

from PIL import Image
import requests
from io import BytesIO
import os

import datetime

thumbnail_sizes = [400, 200, 100, 50]

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
            self.test_url()

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

        if self.is_img():
            self.create_thumbnails()

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

    def absolute_file_path(self, thumbnail_height=None):
        return os.path.join(current_app.config['BASE_DIR'], self.file_path(thumbnail_height))

    def test_video_link(self):
        media_type = self.media_type()
        url = self.data['media_url']
        if media_type == 'Vidéo Youtube' and 'youtube' not in url:
            return False
        
        if media_type == 'Vidéo Dailymotion' and 'dailymotion' not in url:
            return False

        if media_type == 'Vidéo Vimeo' and 'vimeo' not in url:
            return False

        return True

    def test_header_content_type(self, content_type):
        media_type = self.media_type()
        if media_type == 'Photo' and 'image' not in content_type:
            return False

        if media_type == 'Audio' and 'audio' not in content_type:
            return False
        
        if media_type == 'Vidéo (Fichier)' and 'video' not in content_type:
            return False

        if media_type == 'PDF' and 'pdf' not in content_type:
            return False

        if media_type == 'Page web' and 'html' not in content_type:
            return False

        return True

    def test_url(self):
        print('test url', self.data['media_url'])
        try:
            res=requests.head(url=self.data['media_url'])

            print(res.status_code, res)
            if res.status_code != 200:
                raise GeoNatureError(
                    'la réponse est différente de 200 ({})'
                    .format(res.status_code
                    )
                )

            print(res.headers['Content-type'])
            if not self.test_header_content_type(res.headers['Content-type']):
                raise GeoNatureError(
                    'le format du liens ({}) ne corespont pas au type de média choisi ({})'
                    .format(
                        res.headers['Content-type'],
                        self.media_type()
                    )
                )

            if not self.test_video_link():
                raise GeoNatureError(
                    "l'URL n est pas valide pour le type de média choisi ({})"
                    .format(
                        self.media_type()
                    )
                )

        except GeoNatureError as e:
            raise GeoNatureError(
                "Il y a un problème avec l'URL renseignée : {}"
                .format(str(e))
            )
            pass




    def file_path(self, thumbnail_height=None):
        file_path = None
        if self.media.media_path:
            file_path = self.media.media_path
        else:
            file_path = os.path.join(
                current_app.config['UPLOAD_FOLDER'],
                str(self.media.id_table_location),
                "{}_{}".format(self.media.id_media, self.media.media_url.split('/')[-1])
            )

        if(thumbnail_height):
            file_path = file_path.replace('.', '_thumbnail_{}.'.format(thumbnail_height))
            file_path = file_path.replace(current_app.config['UPLOAD_FOLDER'], current_app.config['UPLOAD_FOLDER'] + '/thumbnails')
        return file_path


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

    def is_img(self):
        return self.media_type() == 'Photo'

    def media_type(self):
        nomenclature = (
            DB.session.query(TNomenclatures)
            .filter(TNomenclatures.id_nomenclature == self.data['id_nomenclature_media_type'])
            .one()
        )
        return nomenclature.label_fr

    def get_image(self):
        image = None
        print(self.media.media_path)
        if self.media.media_path:
            image = Image.open(self.absolute_file_path())

        if self.media.media_url:
            response = requests.get(self.media.media_url)
            image = Image.open(BytesIO(response.content))
        
        return image


    def has_thumbnails(self):
        for thumbnail_height in thumbnail_sizes:
            if not os.path.isfile(self.absolute_file_path(thumbnail_height)):
                return False
        return True

    def create_thumbnails(self):

        if self.has_thumbnails():
            return

        try:
            image = self.get_image()
        except Exception as e:
            if self.data['isFile']:
                raise GeonatureError('Le fichier fournit ne contient pas une image valide')
            else:
                raise GeoNatureError('L URL renseignée ne contient pas une image valide')


        for thumbnail_height in thumbnail_sizes:

            width = thumbnail_height / image.size[1] * image.size[0] 
            image.thumbnail((width, thumbnail_height))
            pathlib.Path(
                "/".join(self.absolute_file_path(thumbnail_height).split('/')[:-1])
            ).mkdir(parents=True, exist_ok=True)
            print(self.absolute_file_path(thumbnail_height))
            image.save(self.absolute_file_path(thumbnail_height))

    def delete(self):
        # Note si SQLALCHEMY_TRACK_MODIFICATIONS  = true alors suppression du fichier gérée automatiquement

        # Suppression du média physiquement
        # En réalité renommage
        initial_path = self.media.media_path

        if self.media.media_path and not current_app.config['SQLALCHEMY_TRACK_MODIFICATIONS']:
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
