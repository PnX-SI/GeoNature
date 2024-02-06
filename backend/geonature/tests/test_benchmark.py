from .utils import set_logged_user
from .fixtures import users
from .test_pr_occhab import stations
from flask import url_for
import pytest


class GetLatter:
    def __init__(self, value) -> None:
        self.value = value


def generate_func_test(func, *args, **kwargs):
    fixture = kwargs.pop("fixture", [])
    user_profile = kwargs.pop("user_profile", None)

    if user_profile:
        fixture = fixture + [users]

    def _f_to_include_fixture(self, *fixture):

        def test_function(self, benchmark, users):

            if user_profile:
                if not user_profile in users:
                    raise KeyError(f"{user_profile} can't be found in the users fixture !")
                set_logged_user(self.client, users[user_profile])
            benchmark(
                eval(func.value) if isinstance(func, GetLatter) else func,
                *[eval(arg.value) if isinstance(arg, GetLatter) else arg for arg in args],
                **kwargs,
            )

        return test_function

    return _f_to_include_fixture(*fixture)


tests = [
    [
        GetLatter("self.client.get"),
        "get_station",
        [GetLatter("""url_for("occhab.get_station", id_station=8)""")],
        dict(user_profile="user", fixture=[stations]),
    ],
    [
        GetLatter("self.client.get"),
        "get_default_nomenclatures",
        [GetLatter("""url_for("gn_synthese.getDefaultsNomenclatures")""")],
        dict(user_profile="self_user"),
    ],
]


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestBenchie:
    pass


for func, name, args, kwargs in tests:
    setattr(TestBenchie, f"test_{name}", generate_func_test(func, *args, **kwargs))

# print(dir(TestBenchie))


# def test_routes(app):
#     for rule in app.url_map.iter_rules():
#         print(rule.endpoint)
