import { DataFormService } from '@geonature_common/form/data-form.service';
import { ValidatorFn, AbstractControl, ValidationErrors } from '@angular/forms';
import { Injectable } from '@angular/core';
import { HttpClient, HttpEvent, HttpParams, HttpRequest } from '@angular/common/http';
import { Observable, of, Subject } from '@librairies/rxjs';
import { map, filter, switchMap, tap, pairwise, retry } from "rxjs/operators";
import { AppConfig } from '@geonature_config/app.config';
import { Media } from '@geonature_common/form/media/media';
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

  idTableLocations = [];
  nomenclatures = null;

  constructor(private _http: HttpClient, private _dataFormService: DataFormService) {
    this.getNomenclatures().subscribe();
  }

  getNomenclatures(): Observable<any> {
    if (this.nomenclatures) return of(this.nomenclatures)
    return this._dataFormService
      .getNomenclatures(['TYPE_MEDIA'])
      .pipe(
        switchMap(
          (nomenclatures) => {
            this.nomenclatures = nomenclatures;
            return of(nomenclatures);
          }
        )
      )
  }

  /** une fois que la nomenclature est chargées */
  getNomenclature(value, fieldName = "id_nomenclature", nomenclatureType = null) {
    if (!this.nomenclatures) return null;
    const res = this.nomenclatures
      .filter( N => (!nomenclatureType) || N.mnemonique === nomenclatureType)
      .map( N =>
        N.values.find(n => n[fieldName] === value)
      )
      .filter( n => n);
    return res && res.length == 1 ? res[0] : null;
  }

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
        return media.valid() || media.bLoading;
      });
  }

  mediasValidator(): ValidatorFn {
    return (control: AbstractControl): { [key: string]: boolean } | null => {
      const medias = control.value;
      return !this.validMedias(medias) ? { medias: true } : null;
    }
  }

  href(media) {
    if(! (media instanceof Media)) media = new Media(media);
    return media.href();
  }

  toString(media) {
    if(! (media instanceof Media)) media = new Media(media);
    return `${media.title_fr} : ${media.description_fr} (${this.getNomenclature(media.id_nomenclature_media_type).label_fr}, ${media.author})`;
  }

  toHTML(media) {
    if(! (media instanceof Media)) media = new Media(media);
    return `<a target="_blank" href="${media.href()}">${media.title_fr}</a> : ${media.description_fr} (${this.getNomenclature(media.id_nomenclature_media_type).label_fr}, ${media.author})`;
  }

  typeMedia(media) {
    if(! (media instanceof Media)) media = new Media(media);
    return this.getNomenclature(media.id_nomenclature_media_type).label_fr
  }

  isImg(media) {
    return this.typeMedia(media) === 'Photo';
  }

}
