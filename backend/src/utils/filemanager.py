#coding: utf8
from werkzeug.utils import secure_filename
from flask import current_app

import os
import unicodedata
import re

def remove_file(filepath):
    try :
        os.remove(os.path.join(current_app.config['BASE_DIR'], filepath))
    except :
        pass

def rename_file(old_chemin, old_title, new_title):
    new_chemin = old_chemin.replace(removeDisallowedFilenameChars(old_title),removeDisallowedFilenameChars(new_title))
    os.rename(os.path.join(current_app.config['BASE_DIR'],old_chemin), os.path.join(current_app.config['BASE_DIR'], new_chemin))
    return new_chemin

def upload_file(file, id_media, cd_ref, titre):
    filename = str(cd_ref)+ '_' + str(id_media) + '_' + removeDisallowedFilenameChars(titre) + '.' + file.filename.rsplit('.', 1)[1]
    filepath = os.path.join(current_app.config['UPLOAD_FOLDER'], filename)
    file.save(os.path.join(current_app.config['BASE_DIR'], filepath))
    return filepath

def removeDisallowedFilenameChars(uncleanString):
    cleanedString = secure_filename(uncleanString)
    cleanedString = unicodedata.normalize('NFKD', uncleanString)
    cleanedString = re.sub('[ ]+', '_', cleanedString)
    cleanedString = re.sub('[^0-9a-zA-Z_-]', '', cleanedString)
    return cleanedString