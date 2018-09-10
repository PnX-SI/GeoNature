import requests


def get(url, auth=None):
    try:
        r = requests.get(url, auth=auth)
    except requests.exceptions.RequestException as e:
        raise
    return r


def post(url, json={}):
    try:
        r = requests.post(url, json=json)
    except requests.exceptions.RequestException as e:
        raise
    return r
