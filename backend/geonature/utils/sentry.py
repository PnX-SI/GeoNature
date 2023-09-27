from contextlib import nullcontext

from flask import current_app


def start_sentry_child(*args, **kwargs):
    if not current_app.config.get("SENTRY_DSN"):
        return nullcontext()

    from sentry_sdk import Hub

    span = Hub.current.scope.span
    if span is None:
        return nullcontext()

    return span.start_child(*args, **kwargs)
