import os
import unicodedata
import shutil
import logging
import datetime
import re

from werkzeug.utils import secure_filename
from flask import current_app

# get the root logger
log = logging.getLogger()


def remove_file(filepath):
    try:
        os.remove(os.path.join(current_app.config['BASE_DIR'], filepath))
    except Exception:
        pass


def rename_file(old_chemin, old_title, new_title):
    new_chemin = old_chemin.replace(
        removeDisallowedFilenameChars(old_title),
        removeDisallowedFilenameChars(new_title)
    )
    os.rename(
        os.path.join(current_app.config['BASE_DIR'], old_chemin),
        os.path.join(current_app.config['BASE_DIR'], new_chemin)
    )
    return new_chemin


def upload_file(file, id_media, cd_ref, titre):

    filename = (
        "{cd_ref}_{id_media}_{title}.{ext}"
    ).format(
        cd_ref=str(cd_ref),
        id_media=str(id_media),
        title=removeDisallowedFilenameChars(titre),
        ext=file.filename.rsplit('.', 1)[1]
    )
    filepath = os.path.join(
        current_app.config['UPLOAD_FOLDER'],
        filename
    )
    file.save(os.path.join(current_app.config['BASE_DIR'], filepath))
    return filepath


def removeDisallowedFilenameChars(uncleanString):
    cleanedString = secure_filename(uncleanString)
    cleanedString = unicodedata.normalize('NFKD', uncleanString)
    cleanedString = re.sub('[ ]+', '_', cleanedString)
    cleanedString = re.sub('[^0-9a-zA-Z_-]', '', cleanedString)
    return cleanedString


def delete_recursively(path_folder, period=1, excluded_files=[]):
    """
    Delete all the files and directory inside a directory
    which have been create before a certain period
    Paramters:
        path_folder(string): path to the fomlder to delete
        period(integer): in days: delete the file older than this period
        exluded_files(list<string>): list of files to not delete
    """
    for the_file in os.listdir(path_folder):
        file_path = os.path.join(path_folder, the_file)

        try:
            now = datetime.datetime.now()
            creation_date = datetime.datetime.utcfromtimestamp(os.path.getctime(file_path))
            is_older_than_period = (now - creation_date).days >= period
            if is_older_than_period:
                if os.path.isfile(file_path) and not the_file in excluded_files:
                    os.unlink(file_path)
                elif os.path.isdir(file_path):
                    shutil.rmtree(file_path)
        except Exception as e:
            log.error(e)
