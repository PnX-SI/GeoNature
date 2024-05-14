from geonature.core.gn_commons.models import AbstractMixin
from geonature.core.imports.models import TImports

from bokeh.models.layouts import Row

from abc import abstractmethod
import typing


class ImportStatisticsLabels(typing.TypedDict):
    key: str
    value: str

class ImportInputUrl(typing.TypedDict):
    url: str
    label: str


class ImportMixin(AbstractMixin):
    @staticmethod
    @abstractmethod
    def statistics_labels() -> typing.List[ImportStatisticsLabels]:
        pass

    # The output of this method is NEVER used
    @staticmethod
    @abstractmethod
    def preprocess_transient_data(imprt: TImports, df) -> set:
        return None

    @staticmethod
    @abstractmethod
    def check_transient_data(task, logger, imprt: TImports) -> None:
        pass

    @staticmethod
    @abstractmethod
    def import_data_to_destination(imprt: TImports) -> None:
        pass

    @staticmethod
    @abstractmethod
    def remove_data_from_destination(imprt: TImports) -> None:
        pass

    @staticmethod
    @abstractmethod
    def report_plot(imprt: TImports) -> Row:
        pass

    @staticmethod
    @abstractmethod
    def compute_bounding_box(imprt: TImports) -> None:
        pass
