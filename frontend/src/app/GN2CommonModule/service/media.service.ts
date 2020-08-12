import { ValidatorFn, AbstractControl, ValidationErrors } from '@angular/forms';
import { Injectable } from '@angular/core';
import { HttpClient, HttpEvent, HttpParams, HttpRequest } from '@angular/common/http';
import { Observable, of, Subject } from '@librairies/rxjs';
import { AppConfig } from '@geonature_config/app.config';
import { Media } from '../form/media/media';
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
 *
 */
@Injectable()
export class MediaService {

  idTableLocations = {};

  constructor(private _http: HttpClient) { }

  postMedia(file: File, media): Observable<HttpEvent<any>> {
    const formData = new FormData();
    const postData = media;
    for (const p in postData) {
      if (typeof postData[p] != 'function') {
        formData.append(p, postData[p]);
      }
    }

    formData.append('file', file);
    const params = new HttpParams();


    const url = `${AppConfig.API_ENDPOINT}/gn_commons/media`;

    const req = new HttpRequest('POST', url, formData, {
      params: params,
      reportProgress: true,
      responseType: 'json',
    });
    const id_request = String(Math.random())
    return this._http.request(req);
  }

  deleteMedia(idMedia) {
    return this._http.delete(`${AppConfig.API_ENDPOINT}/gn_commons/media/${idMedia}`)
  }

  getIdTableLocation(schemaDotTable): Observable<number> {
    let idTableLocation = this.idTableLocations[schemaDotTable];
    if (idTableLocation) {
      return of(idTableLocation)
    } else {
      return this._http
        .get<any>(`${AppConfig.API_ENDPOINT}/gn_commons/get_id_table_location/${schemaDotTable}`)
        .pipe()
        .switchMap((idTableLocation) => {
          this.idTableLocations[schemaDotTable] = idTableLocation;
          return of(idTableLocation)
        })
    }
  }

  validMedias(medias) {
    return !medias ||
    !medias.length ||
    medias.every((mediaData) => {
      const media = new Media(mediaData);
      return media.valid();
    });
  }

  validOrLoadingMedias(medias) {
    return !medias ||
    !medias.length ||
    medias.every((mediaData) => {
      const media = new Media(mediaData);
      return media.valid() || media.bLoading;
    });
  }

  mediasValidator(): ValidatorFn {
    return (control: AbstractControl): { [key: string]: boolean } | null => {
      const medias = control.value;
      return !this.validMedias(medias) ? {medias: true} : null;
    }
  }

}
