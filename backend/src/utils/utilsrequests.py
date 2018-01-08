# coding: utf8
import requests

def get(url, auth=None):
    try:
        r = requests.get(url, auth)
        assert r.status_code == 200
    except requests.exceptions.RequestException as e:
        raise
    except AssertionError:
        raise
    return r

def post(url, json={}):
    try:
        r = requests.get(url, json = json)
        assert r.status_code == 200
    except requests.exceptions.RequestException as e:
        raise
    except AssertionError:
        raise
    return r