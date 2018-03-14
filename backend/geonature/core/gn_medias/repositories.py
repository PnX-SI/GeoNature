

from sqlalchemy.exc import IntegrityError

from geonature.utils.env import DB
from geonature.core.gn_medias.models import TMedias
from geonature.core.gn_medias.file_manager import upload_file


class TMediaRepository():
    '''
        Reposity permettant de manipuler un objet média
        au niveau de la base de données et du système de fichier
        de façon synchrone
    '''
    def save(self, data, file):
        # @TODO récupérer les exceptions

        try:
            # filtrer les données du dict qui
            # vont être insérées dans l'objet TMedias
            media_data = {
                k: data[k] for k in TMedias.__mapper__.c.keys() if k in data
            }
            media = TMedias(**media_data)
            DB.session.add(media)
            DB.session.commit()
        except IntegrityError as e:
            # @TODO envoyer exceptions spécialisées
            if 'check_entity_field_exist' in e.args[0]:
                raise Exception(
                    "{} doesn't exists".format(data['entity_name'])
                )
            if 'fk_t_medias_check_entity_value' in e.args[0]:
                raise Exception(
                    "id {} of {} doesn't exists".format(
                        data['entity_value'],
                        data['entity_name']
                    )
                )

        filepath = self.upload_file(file, data['entity_name'], media.id_media)
        media.path = filepath
        try:
            DB.session.add(media)
            DB.session.commit()
        except Exception:
            DB.session.rollback()
        return media

    def upload_file(self, file, entity_name, id_media):
        # @TODO récupérer les exceptions
        filepath = upload_file(
            file,
            entity_name,
            "{id_media}_{file_name}".format(
                id_media=id_media,
                file_name=file.filename
            )
        )
        return filepath

    def update(self):
        pass

    def delete(self):
        pass

    def get(self):
        pass
