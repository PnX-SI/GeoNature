from geonature.core.imports.models import TImports

from bokeh.embed.standalone import StandaloneEmbedJson

import typing


class ImportStatisticsLabels(typing.TypedDict):
    key: str
    value: str


class ImportInputUrl(typing.TypedDict):
    url: str
    label: str


class ImportActions:
    @staticmethod
    def statistics_labels() -> typing.List[ImportStatisticsLabels]:
        raise NotImplementedError

    @staticmethod
    def process_fields(destination, fields):
        pass # because optional

    # The output of this method is NEVER used
    @staticmethod
    def preprocess_transient_data(imprt: TImports, df) -> set:
        raise NotImplementedError

    @staticmethod
    def check_transient_data(task, logger, imprt: TImports) -> None:
        raise NotImplementedError

    @staticmethod
    def import_data_to_destination(imprt: TImports) -> None:
        raise NotImplementedError

    @staticmethod
    def remove_data_from_destination(imprt: TImports) -> None:
        raise NotImplementedError

    @staticmethod
    def report_plot(imprt: TImports) -> StandaloneEmbedJson:
        raise NotImplementedError

    @staticmethod
    def compute_bounding_box(imprt: TImports) -> None:
        raise NotImplementedError
