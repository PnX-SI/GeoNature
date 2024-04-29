from typing import Any
from geonature.tests.utils import set_logged_user
from geonature.tests.fixtures import users

import importlib
from geonature.tests.benchmarks import *


class CLater:
    def __init__(self, value) -> None:
        self.value = value


class BenchmarkTest:
    """
    Class that allows to define a benchmark test and generate the pytest function to run the benchmark.

    Example, in a pytest file:
    ```python
    import pytest
    bench = BenchmarkTest(print,"test_print",["Hello","World"],{})
    @pytest.mark.usefixtures("client_class", "temporary_transaction")
        class TestBenchie:
            pass
    TestBenchie.test_print = bench()
    ```

    If a function or its argument depend on the pytest function context, use the GetLatter class : GetLatter("<python expression">). For example, to use
    the `url_for()` function, replace from `url_for(...)` to `GetLatter("url_for(...)")`.

    If the benchmark requires a user to be logged, use the `function_kwargs` with the "user_profile" key and the value corresponds to a key
    available in the dictionary returned by the `user` fixture.


    """

    def __init__(self, function, function_args=[], function_kwargs={}) -> None:
        """
        Constructor of BenchmarkTest

        Parameters
        ----------
        function : Callable | GetLatter
            function that will be benchmark
        function_args : Sequence[Any | GetLatter]
            args for the function
        function_kwargs : Dict[str,Any]
            kwargs for the function
        """
        self.function = function
        self.function_args = function_args
        self.function_kwargs = function_kwargs

    def __call__(self, *args: Any, **kwds: Any) -> Any:
        return self.generate_func_test()

    def generate_func_test(self):
        """
        Return the pytest function to run the benchmark on the indicated function.

        Returns
        -------
        Callable
            test function

        Raises
        ------
        KeyError
            if the user_profile given do not exists
        """

        fixtures = self.function_kwargs.pop("fixtures", [])
        user_profile = self.function_kwargs.pop("user_profile", None)

        func, args, kwargs = self.function, self.function_args, self.function_kwargs

        def function_to_include_fixture(*fixture):

            def final_test_function(self, benchmark, users):

                if user_profile:
                    if not user_profile in users:
                        raise KeyError(f"{user_profile} can't be found in the users fixture !")
                    set_logged_user(self.client, users[user_profile])
                benchmark(
                    eval(func.value) if isinstance(func, CLater) else func,
                    *[eval(arg.value) if isinstance(arg, CLater) else arg for arg in args],
                    **{
                        key: eval(value.value) if isinstance(value, CLater) else value
                        for key, value in kwargs.items()
                    },
                )

            return final_test_function

        return function_to_include_fixture(*fixtures)
