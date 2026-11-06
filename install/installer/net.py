"""Téléchargements avec retry, écriture atomique et vérification optionnelle de l'empreinte."""

import hashlib
import os
import time
import urllib.error
import urllib.request
from pathlib import Path


class DownloadError(RuntimeError):
    pass


def download(
    url, dest, attempts=4, timeout=30, sha256=None, sleep=time.sleep, opener=urllib.request.urlopen
):
    """Télécharge `url` vers `dest` ; ne laisse jamais de fichier partiel. Retourne `dest`."""
    dest = Path(dest)
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_name(dest.name + ".part")
    last = None
    for attempt in range(1, attempts + 1):
        try:
            digest = hashlib.sha256()
            with opener(url, timeout=timeout) as resp, open(tmp, "wb") as out:
                while chunk := resp.read(1 << 20):
                    digest.update(chunk)
                    out.write(chunk)
            if sha256 and digest.hexdigest() != sha256:
                raise DownloadError(f"empreinte inattendue pour {url}")
            os.replace(tmp, dest)
            return dest
        except (urllib.error.URLError, OSError, DownloadError) as e:
            last = e
            tmp.unlink(missing_ok=True)
            if isinstance(e, urllib.error.HTTPError) and 400 <= e.code < 500:
                break  # une erreur client ne se résout pas en réessayant
            if attempt < attempts:
                sleep(2**attempt)
    raise DownloadError(f"Échec du téléchargement de {url} : {last}")
