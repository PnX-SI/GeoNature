"""Tests for geonature.plugins, the custom/python/ plugin mechanism.

custom/python/ is a repo-root directory (gitignored except for tracked
.gitkeep placeholders) where instance admins may drop custom Python modules
(e.g. custom authentication providers) that must survive `geonature
update`/git pulls. geonature.plugins is a regular package whose __init__.py
extends its own __path__ to also look inside custom/python/, so that files
dropped there become importable under the `geonature.plugins` dotted-name
namespace (e.g. custom/python/providers/my_provider.py becomes
geonature.plugins.providers.my_provider) and can be referenced from
geonature_config.toml's AUTHENTICATION.PROVIDERS[].module.
"""

from pathlib import Path

import pytest
from marshmallow import EXCLUDE, ValidationError
from pypnusershub.auth.authentication import ProviderConfigurationSchema

import geonature.plugins
from geonature.utils import env


class TestGeonaturePlugins:
    def test_custom_python_dir_is_on_plugins_path(self):
        # custom/python/.gitkeep is tracked in git, so CUSTOM_PYTHON_DIR
        # always exists in any checkout/CI run. This locks in that
        # geonature/plugins/__init__.py's __path__ extension actually
        # happened (e.g. catches someone renaming/removing that line, or
        # someone deleting custom/python/.gitkeep).
        assert env.CUSTOM_PYTHON_DIR in [Path(p) for p in geonature.plugins.__path__]

    def test_provider_config_resolves_module_from_plugins_namespace(self, tmp_path, monkeypatch):
        # This is the actual contract the custom/python/ feature depends on:
        # once a directory is merged into geonature.plugins.__path__, a
        # <dir>/providers/<module>.py file becomes importable as
        # geonature.plugins.providers.<module> (an implicit PEP 420
        # namespace package, no __init__.py needed for `providers/`), and
        # GeoNature's provider config (via pypnusershub's
        # ProviderConfigurationSchema) resolves it by
        # "<dotted module path>.<ClassName>".
        monkeypatch.setattr(
            geonature.plugins,
            "__path__",
            geonature.plugins.__path__ + [str(tmp_path)],
        )

        providers_dir = tmp_path / "providers"
        providers_dir.mkdir()
        # Distinct name from custom/python/providers/dummy_provider.py (the
        # tracked manual-testing example) to avoid any risk of colliding
        # with it or with a stale sys.modules cache entry.
        provider_module = providers_dir / "dummy_custom_provider_for_tests.py"
        provider_module.write_text(
            "from pypnusershub.auth import Authentication\n"
            "\n"
            "\n"
            "class DummyCustomProvider(Authentication):\n"
            "    id_provider = 'dummy_custom_provider_for_tests'\n"
            "    label = 'Dummy custom provider (test)'\n"
        )

        # Positive case: the module/class exist and are importable through
        # the geonature.plugins namespace, so loading the config must not
        # raise.
        data = ProviderConfigurationSchema().load(
            {
                "module": "geonature.plugins.providers.dummy_custom_provider_for_tests.DummyCustomProvider",
                "id_provider": "test_provider",
            },
            unknown=EXCLUDE,
        )
        assert (
            data["module"]
            == "geonature.plugins.providers.dummy_custom_provider_for_tests.DummyCustomProvider"
        )

        # Negative case: a bogus module path must still raise
        # ValidationError, so this test cannot become a no-op that passes
        # even when nothing is really being validated.
        with pytest.raises(ValidationError):
            ProviderConfigurationSchema().load(
                {
                    "module": "geonature.plugins.providers.not_a_real_module_xyz.NotARealClass",
                    "id_provider": "test_provider",
                },
                unknown=EXCLUDE,
            )
