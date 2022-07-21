import os
import pathlib
import re
import unicodedata

from shutil import rmtree
from werkzeug.utils import secure_filename
from flask import current_app


def remove_dir(dirpath):
    if dirpath == "/":
        raise Exception("rm / is not possible")

    if not os.path.exists(dirpath):
        raise FileNotFoundError("not exists {}".format(dirpath))
    if not os.path.isdir(dirpath):
        raise FileNotFoundError("not isdir {}".format(dirpath))

    try:
        rmtree(dirpath)
    except (OSError, IOError) as e:
        raise e


def remove_file(filepath):
    try:
        os.remove(os.path.join(current_app.config["BASE_DIR"], filepath))
    except FileNotFoundError:
        pass
    except Exception as e:
        raise e


def rename_file(old_path, new_path):
    os.rename(
        os.path.join(current_app.config["BASE_DIR"], old_path),
        os.path.join(current_app.config["BASE_DIR"], new_path),
    )
    return new_path


def upload_file(file, file_folder, file_name):
    ext = file.filename.rsplit(".", 1)[1]

    filedir = os.path.join(current_app.config["UPLOAD_FOLDER"], file_folder)

    pathlib.Path(os.path.join(current_app.config["BASE_DIR"], filedir)).mkdir(
        parents=True, exist_ok=True
    )

    filepath = os.path.join(
        filedir,
        "{file_name}.{ext}".format(
            file_name=removeDisallowedFilenameChars(file_name.rsplit(".", 1)[0]),
            ext=ext,
        ),
    )
    try:
        file.save(os.path.join(current_app.config["BASE_DIR"], filepath))
    except FileNotFoundError as e:
        raise e
    return filepath


def removeDisallowedFilenameChars(uncleanString):
    cleanedString = secure_filename(uncleanString)
    cleanedString = unicodedata.normalize("NFKD", uncleanString)
    cleanedString = re.sub("[ ]+", "_", cleanedString)
    cleanedString = re.sub("[^0-9a-zA-Z_-]", "", cleanedString)
    return cleanedString
