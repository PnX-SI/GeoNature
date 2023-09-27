import { DataFormService } from '@geonature_common/form/data-form.service';
import { ValidatorFn, AbstractControl } from '@angular/forms';
import { Injectable } from '@angular/core';
import { HttpClient, HttpEvent, HttpParams, HttpRequest } from '@angular/common/http';
import { Observable, of } from '@librairies/rxjs';
import { switchMap } from 'rxjs/operators';
import { Media } from '@geonature_common/form/media/media';
import { ConfigService } from '@geonature/services/config.service';

const _NOMENCLATURES = ['TYPE_MEDIA'];
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
  bInitialized = false;

  constructor(
    private _http: HttpClient,
    private _dataFormService: DataFormService,
    public config: ConfigService
  ) {
    // initialisation des nomenclatures
    this.getNomenclatures().subscribe(() => {
      this.bInitialized = true;
    });
  }

  metaNomenclatures() {
    const nomenclatures = {};
    for (const nomenclature of this.nomenclatures.find((N) => N.mnemonique === 'TYPE_MEDIA')[
      'values'
    ]) {
      nomenclatures[nomenclature.id_nomenclature] = nomenclature;
    }
    return nomenclatures;
  }

  getNomenclatures(): Observable<any> {
    if (this.nomenclatures) return of(this.nomenclatures);
    return this._dataFormService.getNomenclatures(_NOMENCLATURES).pipe(
      switchMap((nomenclatures) => {
        this.nomenclatures = nomenclatures;
        return of(nomenclatures);
      })
    );
  }

  /** une fois que la nomenclature est chargées */
  getNomenclature(value, fieldName = 'id_nomenclature', nomenclatureType = null) {
    if (!value) {
      return {};
    }
    if (!this.nomenclatures) return {};
    const res = this.nomenclatures
      .filter((N) => !nomenclatureType || N.mnemonique === nomenclatureType)
      .map((N) => N.values.find((n) => n[fieldName] === value))
      .filter((n) => n);
    return res && res.length == 1 ? res[0] : null;
  }

  getMedias(uuidAttachedRow): Observable<any> {
    return this._http.get(`${this.config.API_ENDPOINT}/gn_commons/medias/${uuidAttachedRow}`);
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

    const url = `${this.config.API_ENDPOINT}/gn_commons/media`;

    const req = new HttpRequest('POST', url, formData, {
      params: params,
      reportProgress: true,
      responseType: 'json',
    });
    return this._http.request(req);
  }

  deleteMedia(idMedia) {
    return this._http.delete(`${this.config.API_ENDPOINT}/gn_commons/media/${idMedia}`);
  }

  getIdTableLocation(schemaDotTable): Observable<number> {
    let idTableLocation = this.idTableLocations[schemaDotTable];
    if (idTableLocation) {
      return of(idTableLocation);
    } else {
      return this._http
        .get<any>(`${this.config.API_ENDPOINT}/gn_commons/get_id_table_location/${schemaDotTable}`)
        .pipe(
          switchMap((idTableLocation) => {
            this.idTableLocations[schemaDotTable] = idTableLocation;
            return of(idTableLocation);
          })
        );
    }
  }

  validMedias(medias) {
    return (
      !medias ||
      !medias.length ||
      medias.every((mediaData) => {
        const media = new Media(mediaData);
        return media.valid();
      })
    );
  }

  validOrLoadingMedias(medias) {
    return (
      !medias ||
      !medias.length ||
      medias.every((mediaData) => {
        const media = new Media(mediaData);
        return media.valid() || media.bLoading;
      })
    );
  }

  mediasValidator(): ValidatorFn {
    return (control: AbstractControl): { [key: string]: boolean } | null => {
      const medias = control.value;
      return !this.validMedias(medias) ? { medias: true } : null;
    };
  }

  href(media, thumbnail = null) {
    if (!(media instanceof Media)) {
      media = new Media(media);
    }
    return media.href(this.config.API_ENDPOINT, this.config.MEDIA_URL, thumbnail);
  }

  embedHref(media) {
    if (!(media instanceof Media)) {
      media = new Media(media);
    }
    if (['Vidéo Youtube'].includes(this.typeMedia(media))) {
      const v_href = media.href(this.config.API_ENDPOINT, this.config.MEDIA_URL).split('/');
      const urlLastPart = v_href[v_href.length - 1];
      const videoId = urlLastPart.includes('?')
        ? urlLastPart.includes('v=')
          ? urlLastPart
              .split('?')
              .find((s) => s.includes('v='))
              .replace('v=', '')
          : urlLastPart.split('?')[0]
        : urlLastPart;
      return `https://www.youtube.com/embed/${videoId}`;
    }
    if (['Vidéo Dailymotion'].includes(this.typeMedia(media))) {
      const v = media.href(this.config.API_ENDPOINT, this.config.MEDIA_URL).split('/');
      const videoId = v[v.length - 1].split('?')[0];
      return `https://www.dailymotion.com/embed/video/${videoId}`;
    }

    if (['Vidéo Vimeo'].includes(this.typeMedia(media))) {
      const v = media.href(this.config.API_ENDPOINT, this.config.MEDIA_URL).split('/');
      const videoId = v[v.length - 1].split('?')[0];
      return `https://player.vimeo.com/video/${videoId}`;
    }

    return media.href(this.config.API_ENDPOINT, this.config.MEDIA_URL);
  }

  icon(media) {
    if (!(media instanceof Media)) {
      media = new Media(media);
    }
    const typeMedia = this.typeMedia(media);
    if (typeMedia === 'PDF') {
      return 'picture_as_pdf';
    }
    if (
      ['Vidéo Dailymotion', 'Vidéo Youtube', 'Vidéo Vimeo', 'Vidéo (fichier)'].includes(typeMedia)
    ) {
      return 'videocam';
    }
    if (typeMedia === 'Audio') {
      return 'audiotrack';
    }
    if (typeMedia === 'Photo') {
      return 'insert_photo';
    }
    if (typeMedia === 'Page web') {
      return 'web';
    }
  }

  toString(media) {
    if (!(media instanceof Media)) {
      media = new Media(media);
    }
    const description = media.description_fr ? ` : ${media.description_fr}` : '';
    const details =
      this.typeMedia(media) || media.author
        ? `(${this.getNomenclature(media.id_nomenclature_media_type).label_fr}${
            media.author ? 'par ' + media.author : ''
          })`
        : '';
    return `${media.title_fr} ${description} ${details}`.trim();
  }

  toHTML(media) {
    if (!(media instanceof Media)) {
      media = new Media(media);
    }
    return `<a target="_blank" href="${media.href(
      this.config.API_ENDPOINT,
      this.config.MEDIA_URL
    )}">${media.title_fr}</a> : ${media.description_fr} (${
      this.getNomenclature(media.id_nomenclature_media_type).label_fr
    }, ${media.author})`;
  }

  typeMedia(media) {
    if (!(media instanceof Media)) {
      media = new Media(media);
    }
    return this.getNomenclature(media.id_nomenclature_media_type).label_fr;
  }

  isImg(media) {
    return this.typeMedia(media) === 'Photo';
  }

  tooltip(media) {
    if (!(media instanceof Media)) {
      media = new Media(media);
    }
    let tooltip = `<a
    href=${media.href(this.config.API_ENDPOINT, this.config.MEDIA_URL)}
    title="${this.toString(media)}"
    target="_blank"
    style="margin: 0 2px"
    >`;
    if (this.typeMedia(media) === 'Photo') {
      tooltip += `<img style='
      height: 50px; width: 50px; border-radius: 25px; object-fit: cover;
      '
      src='${media.href(this.config.API_ENDPOINT, this.config.MEDIA_URL, 50)}' alt='${
        media.title_fr
      }' >`; // TODO PARAMETERS => taille des thumbnails
    } else {
      tooltip += `
      <div style='
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 50px;
      height: 50px;
      border-radius: 25px;
      background-color: lightgrey;
      vertical-align: middle;
      '
      >
      <div
      style="height:24px;"
      class="material-icons md-24"
      >
      ${this.icon(media)}
      </div>
      </div>
      `;
    }
    tooltip += '</a>';
    return tooltip;
  }
}
