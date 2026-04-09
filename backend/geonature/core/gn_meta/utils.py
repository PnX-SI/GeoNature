import datetime as dt
from geonature.utils.env import db
from geonature.utils.module import is_module_installed
from sqlalchemy.sql import select
from sqlalchemy.sql.functions import func
from geonature.core.gn_synthese.models import Synthese
from geonature.core.gn_meta.models import TDatasets
from geonature.utils.config import config
import geonature.utils.filemanager as fm

if "OCCHAB" in config:
    from gn_module_occhab.models import OccurenceHabitat, Station


def get_acquisition_framework_stats(id_acquisition_framework):
    dataset_ids = db.session.scalars(
        select(TDatasets.id_dataset).where(
            TDatasets.id_acquisition_framework == id_acquisition_framework
        )
    ).all()

    nb_datasets = len(dataset_ids)

    nb_taxons = db.session.execute(
        select(func.count(func.distinct(Synthese.cd_nom))).where(
            Synthese.id_dataset.in_(dataset_ids)
        )
    ).scalar_one()

    nb_observations = db.session.execute(
        select(func.count("*"))
        .select_from(Synthese)
        .where(Synthese.dataset.has(TDatasets.id_acquisition_framework == id_acquisition_framework))
    ).scalar_one()

    nb_habitats = 0

    if (
        is_module_installed("gn_module_occhab", check_if_all_revisions_have_been_applied=False)
        and nb_datasets > 0
    ):

        nb_habitats = db.session.execute(
            select(func.count("*"))
            .select_from(OccurenceHabitat)
            .join(Station)
            .where(Station.id_dataset.in_(dataset_ids))
        ).scalar_one()

    return {
        "nb_dataset": nb_datasets,
        "nb_taxons": nb_taxons,
        "nb_observations": nb_observations,
        "nb_habitats": nb_habitats,
    }


class MetadataPdfBuilder:
    """
    Utility class to build PDF responses for GeoNature metadata exports
    """

    DEFAULT_CSS = {
        "logo": "Logo_pdf.png",
        "bandeau": "Bandeau_pdf.png",
        "entite": "sinp",
    }

    def __init__(self, template, data):
        self.template = template
        self.data = data

    def add_css(self, css: dict = None):
        """Attach CSS assets"""
        if not css:
            css = self.DEFAULT_CSS
        self.data["css"] = css
        return self

    def add_footer(self, url_path):
        """Attach footer"""
        self.data["footer"] = {
            "url": url_path,
            "date": dt.datetime.now().strftime("%d/%m/%Y"),
        }
        return self

    def add_chart_if_provided(self, request):
        """Attach chart if provided in request"""
        if request.is_json and request.json is not None:
            self.data["chart"] = request.json.get("chart")
        return self

    def add_title(
        self,
        title: str = None,
    ):
        self.data["title"] = title
        return self

    def build(self):
        """Generate PDF response"""
        pdf_file = fm.generate_pdf(self.template, self.data)
        return pdf_file
