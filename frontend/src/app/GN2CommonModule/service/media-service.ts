import { Injectable } from '@angular/core';
import { HttpClient, HttpEvent, HttpParams, HttpRequest } from '@angular/common/http';
import { Observable, of, Subject } from '@librairies/rxjs';
import { AppConfig } from '@geonature_config/app.config';

/**
 *
 *  Ce service référence les méthodes pour la gestion des medias
 *
 * inspiré de https://stackoverflow.com/questions/40214772/file-upload-in-angular
 * pour l'upload des fichiers
 */

/**
 *  Les requêtes pour les objects de type nomenclature, utilisateurs, taxonomie ,sont mise en cache
 *
 * @param File fichier ???
 * @param media post data pour le media
 * @param temp temp si media temporaire (pas encore d'uuid_attached_row)
 *
 */
@Injectable()
export class MediaService {

  constructor(private _http: HttpClient) { }

  uploadFile(file: File, media, temp=false): Observable<HttpEvent<any>> {
    const formData = new FormData();
    const postData = media;
    for (const p in postData) {
      if (postData[p]) {
        formData.append(p, postData[p]);
      }
    }

    formData.append('file', file);
    const params = new HttpParams();
    params.set('temp', temp.toString())
    const options = {
      params: params,
      reportProgress: true,
    };

    const url = `${AppConfig.API_ENDPOINT}/gn_commons/media`;

    const req = new HttpRequest('POST', url, formData, options);
    return this._http.request(req);
  }
}
