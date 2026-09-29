import sys

import pytest
from marshmallow import EXCLUDE, ValidationError
from pypnusershub.auth.authentication import ProviderConfigurationSchema


class TestCustomPythonDir:
    def test_custom_python_dir_is_on_sys_path(self):
        # geonature.utils.env is already imported transitively (e.g. via
        # geonature.utils.config / conftest.py) before this test runs, so its
        # module-level `if CUSTOM_PYTHON_DIR.is_dir(): sys.path.append(...)`
        # side effect has already run. custom/python/.gitkeep is tracked in
        # git, so CUSTOM_PYTHON_DIR always exists in any checkout/CI run,
        # meaning this assertion locks in that the wiring stays correct
        # (e.g. catches someone renaming/removing the sys.path.append call,
        # or someone deleting custom/python/.gitkeep).
        from geonature.utils import env

        assert str(env.CUSTOM_PYTHON_DIR) in sys.path

    def test_provider_config_resolves_module_from_sys_path(self, tmp_path, monkeypatch):
        # This is the actual contract the custom/python/ feature depends on:
        # once a directory is on sys.path, GeoNature's provider config
        # (via pypnusershub's ProviderConfigurationSchema) resolves a file in
        # it by "<filename>.<ClassName>".
        provider_module = tmp_path / "dummy_custom_provider.py"
        provider_module.write_text(
            "from pypnusershub.auth import Authentication\n"
            "\n"
            "\n"
            "class DummyCustomProvider(Authentication):\n"
            "    id_provider = 'dummy_custom_provider'\n"
            "    label = 'Dummy custom provider (test)'\n"
        )
        monkeypatch.syspath_prepend(tmp_path)

        # Positive case: the module/class exist and are importable from
        # sys.path, so loading the config must not raise.
        data = ProviderConfigurationSchema().load(
            {
                "module": "dummy_custom_provider.DummyCustomProvider",
                "id_provider": "test_provider",
            },
            unknown=EXCLUDE,
        )
        assert data["module"] == "dummy_custom_provider.DummyCustomProvider"

        # Negative case: a bogus module path that is not on sys.path must
        # still raise ValidationError, so this test cannot become a no-op
        # that passes even when nothing is really being validated.
        with pytest.raises(ValidationError):
            ProviderConfigurationSchema().load(
                {
                    "module": "not_a_real_module_xyz.NotARealClass",
                    "id_provider": "test_provider",
                },
                unknown=EXCLUDE,
            )
