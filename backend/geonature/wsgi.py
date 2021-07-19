"""
    Give a unique entry point for gunicorn
"""

import warnings
from urllib.parse import urlparse

from sqlalchemy import exc as sa_exc
from werkzeug.middleware.proxy_fix import ProxyFix

from geonature import create_app

class ReverseProxied(object):
    def __init__(self, app, script_name=None, scheme=None, server=None):
        self.app = app
        self.script_name = script_name
        self.scheme = scheme
        self.server = server

    def __call__(self, environ, start_response):
        script_name = environ.get("HTTP_X_SCRIPT_NAME", "") or self.script_name
        if script_name:
            environ["SCRIPT_NAME"] = script_name
            path_info = environ["PATH_INFO"]
            if path_info.startswith(script_name):
                environ["PATH_INFO"] = path_info[len(script_name) :]
        scheme = environ.get("HTTP_X_SCHEME", "") or self.scheme
        if scheme:
            environ["wsgi.url_scheme"] = scheme
        server = environ.get("HTTP_X_FORWARDED_SERVER", "") or self.server
        if server:
            environ["HTTP_HOST"] = server
        return self.app(environ, start_response)

# give the app context from server.py in a app object and filter sqlalchemy warning
with warnings.catch_warnings():
    warnings.simplefilter("ignore", category=sa_exc.SAWarning)
    app = create_app()
    app.wsgi_app = ReverseProxied(
        app.wsgi_app, 
        script_name=urlparse(app.config["API_ENDPOINT"]).path
    )
