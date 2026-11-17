"""
Unit tests for the import check hooks (ImportActions.check_transient_data_pre / _df_batch / _post).

No database is needed: the database helpers and the flask config are replaced
at the level of the `geonature.core.imports.actions` module.
"""

import logging
import math
from types import SimpleNamespace

import pytest

from geonature.core.imports import actions as actions_module
from geonature.core.imports.actions import ImportActions, import_hook

LOGGER = logging.getLogger(__name__)


class FakeTask:
    def __init__(self):
        self.progress = []

    def update_state(self, state, meta):
        assert state == "PROGRESS"
        self.progress.append(meta["progress"])


def fake_entity(code, order, validity=True):
    return SimpleNamespace(
        code=code,
        order=order,
        validity_column=f"{code}_valid" if validity else None,
    )


@pytest.fixture
def recorder(monkeypatch):
    """
    Patch the database helpers and record their calls.

    Entities: visit (order 2, 15 valid rows), site (order 1, 15 valid rows), observation
    (no validity column, so not present in the import). Batch size 10: 2 batches per entity.
    """
    rec = SimpleNamespace(
        events=[],
        loads=[],
        loaded_dfs=[],
        updates=[],
        batch_returns={},
        empty_batches=set(),
        valid_rows={"site": 15, "visit": 15},
    )

    monkeypatch.setattr(
        actions_module,
        "current_app",
        SimpleNamespace(config={"IMPORT": {"DATAFRAME_BATCH_SIZE": 10}}),
    )
    monkeypatch.setattr(
        actions_module,
        "get_mapping_data",
        lambda imprt, entity: (None, None, [f"{entity.code}_src"]),
    )

    def load(imprt, entity, source_cols, offset=None, limit=None):
        rec.loads.append((entity.code, tuple(source_cols), offset, limit))
        df = SimpleNamespace(
            entity=entity.code,
            offset=offset,
            empty=(entity.code, offset) in rec.empty_batches,
        )
        rec.loaded_dfs.append(df)
        return df

    def update(imprt, entity, updated_cols, df):
        rec.updates.append((entity.code, updated_cols, df))

    monkeypatch.setattr(actions_module, "load_transient_data_in_dataframe", load)
    monkeypatch.setattr(actions_module, "update_transient_data_from_dataframe", update)

    class RecordingActions(ImportActions):
        @staticmethod
        @import_hook(progress=0.1)
        def check_transient_data_pre(task, logger, imprt, update_progress):
            rec.events.append("pre")
            update_progress(0.5)

        @staticmethod
        @import_hook(progress=0.8)
        def check_transient_data_df_batch(task, logger, imprt, entity, df, update_progress):
            rec.events.append(("batch", entity.code, df.offset))
            update_progress(0.5)
            return rec.batch_returns.get(entity.code)

        @staticmethod
        @import_hook(progress=0.1)
        def check_transient_data_post(task, logger, imprt, update_progress):
            rec.events.append("post")
            update_progress(0.5)

        @staticmethod
        def count_valid_rows(imprt, entity):
            rec.events.append(("count", entity.code))
            return rec.valid_rows[entity.code]

    rec.actions = RecordingActions
    return rec


@pytest.fixture
def imprt():
    entities = [
        fake_entity("visit", 2),
        fake_entity("site", 1),
        fake_entity("observation", 3, validity=False),
    ]
    return SimpleNamespace(id_import=7, destination=SimpleNamespace(entities=entities))


# Expected progress for 2 entities x 2 batches (T = 4), with v = 0.5 in each hook and
# v = 1 after each batch, then the post hook. pre: 0.1 x 0.5 = 0.05, then 0.1 after the
# composer's v = 1.
EXPECTED_PROGRESS = [0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 1.0]


def test_hook_weights_sum_to_one():
    pre = ImportActions.check_transient_data_pre.progress
    batch = ImportActions.check_transient_data_df_batch.progress
    post = ImportActions.check_transient_data_post.progress
    assert (pre, batch, post) == (0.1, 0.8, 0.1)
    assert math.isclose(pre + batch + post, 1)


def test_hook_decorator_attaches_progress():
    @import_hook(progress=0.3)
    def f():
        pass

    assert f.progress == 0.3


def test_weights_not_summing_to_one_are_refused(recorder, imprt):
    class BadWeights(recorder.actions):
        @staticmethod
        @import_hook(progress=0.2)
        def check_transient_data_pre(task, logger, imprt, update_progress):
            pass

    with pytest.raises(AssertionError):
        BadWeights.check_transient_data(None, LOGGER, imprt)


def test_composition_order_and_offsets(recorder, imprt):
    recorder.actions.check_transient_data(None, LOGGER, imprt)

    # Entities ordered by Entity.order; the observation entity (no validity) is skipped.
    # Counts are read after the pre hook, batches are offset/limit slices per entity.
    assert recorder.events == [
        "pre",
        ("count", "site"),
        ("count", "visit"),
        ("batch", "site", 0),
        ("batch", "site", 10),
        ("batch", "visit", 0),
        ("batch", "visit", 10),
        "post",
    ]
    assert recorder.loads == [
        ("site", ("site_src",), 0, 10),
        ("site", ("site_src",), 10, 10),
        ("visit", ("visit_src",), 0, 10),
        ("visit", ("visit_src",), 10, 10),
    ]


def test_batch_count_depends_on_each_entity(recorder, imprt):
    # 25 valid rows for visit (3 batches), 15 for site (2 batches): T = 5
    recorder.valid_rows = {"site": 15, "visit": 25}
    task = FakeTask()
    recorder.actions.check_transient_data(task, LOGGER, imprt)

    visit_loads = [offset for code, _, offset, _ in recorder.loads if code == "visit"]
    assert visit_loads == [0, 10, 20]
    assert task.progress[-1] == pytest.approx(1)
    # Batch progress is computed with T = 5, not with E x N
    batch_values = [p for p in task.progress if 0.1 < p < 0.9]
    assert batch_values[0] == pytest.approx(0.1 + 0.8 * (0 + 0.5) / 5)


def test_entity_without_valid_rows_has_no_batch(recorder, imprt):
    recorder.valid_rows = {"site": 0, "visit": 15}
    recorder.actions.check_transient_data(None, LOGGER, imprt)

    assert [code for code, *_ in recorder.loads] == ["visit", "visit"]


def test_progress_values(recorder, imprt):
    task = FakeTask()
    recorder.actions.check_transient_data(task, LOGGER, imprt)
    assert task.progress == pytest.approx(EXPECTED_PROGRESS)


def test_progress_is_clamped():
    task = FakeTask()
    update = actions_module.get_update_task_progress_callback(task, lambda v: v)
    update(2)
    update(-1)
    update(0.3)
    assert task.progress == pytest.approx([1, 0, 0.3])


def test_progress_without_task_does_not_fail(recorder, imprt):
    recorder.actions.check_transient_data(None, LOGGER, imprt)
    assert recorder.events[0] == "pre"


def test_returned_columns_are_written_back(recorder, imprt):
    recorder.batch_returns = {"site": {"id_base_site"}}
    recorder.actions.check_transient_data(None, LOGGER, imprt)

    assert [(code, cols) for code, cols, _ in recorder.updates] == [
        ("site", {"id_base_site"}),
        ("site", {"id_base_site"}),
        ("visit", None),
        ("visit", None),
    ]
    # The written dataframe is the one loaded for this batch and passed to the hook
    assert [df for _, _, df in recorder.updates] == recorder.loaded_dfs


def test_empty_batches_are_still_called_and_count_for_progress(recorder, imprt):
    recorder.empty_batches = {("visit", 10)}
    task = FakeTask()
    recorder.actions.check_transient_data(task, LOGGER, imprt)

    assert ("batch", "visit", 10) in recorder.events
    assert task.progress == pytest.approx(EXPECTED_PROGRESS)


def test_destination_can_provide_its_source_columns(recorder, imprt):
    class CustomColumns(recorder.actions):
        @staticmethod
        def get_source_cols(imprt, entity):
            return [f"{entity.code}_custom"]

    CustomColumns.check_transient_data(None, LOGGER, imprt)

    assert {source_cols for _, source_cols, _, _ in recorder.loads} == {
        ("site_custom",),
        ("visit_custom",),
    }
