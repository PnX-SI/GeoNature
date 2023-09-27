import os
import unicodedata
import shutil
import datetime
import re
from pathlib import Path

from werkzeug.utils import secure_filename
from flask import current_app, render_template
from weasyprint import HTML, CSS


def removeDisallowedFilenameChars(uncleanString):
    cleanedString = secure_filename(uncleanString)
    cleanedString = unicodedata.normalize("NFKD", uncleanString)
    cleanedString = re.sub("[ ]+", "_", cleanedString)
    cleanedString = re.sub("[^0-9a-zA-Z_-]", "", cleanedString)
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

        now = datetime.datetime.now()
        creation_date = datetime.datetime.utcfromtimestamp(os.path.getctime(file_path))
        is_older_than_period = (now - creation_date).days >= period
        if is_older_than_period:
            if os.path.isfile(file_path) and not the_file in excluded_files:
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)


def generate_pdf(template, data):
    # flask render a template by name with the given context
    template_rendered = render_template(template, data=data)
    # weasyprint HTML document parsed
    html_file = HTML(
        string=template_rendered, base_url=current_app.config["API_ENDPOINT"], encoding="utf-8"
    )
    # weasyprint render the document to a PDF file
    return html_file.write_pdf()
