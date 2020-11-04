import { DataFormService } from '@geonature_common/form/data-form.service';
import { ValidatorFn, AbstractControl, ValidationErrors } from '@angular/forms';
import { Injectable } from '@angular/core';
import { HttpClient, HttpEvent, HttpParams, HttpRequest } from '@angular/common/http';
import { Observable, of, Subject } from '@librairies/rxjs';
import { map, filter, switchMap, tap, pairwise, retry } from 'rxjs/operators';
import { AppConfig } from '@geonature_config/app.config';
import { Media } from '@geonature_common/form/media/media';
import { NgbDateParserFormatter } from "@ng-bootstrap/ng-bootstrap";

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
    private dateParser: NgbDateParserFormatter,
    ) {
    // initialisation des nomenclatures
    this.getNomenclatures().subscribe(() => {
      this.bInitialized = true;
    });
  }

  metaNomenclatures() {
    const nomenclatures = {};
    for (const nomenclature of this.nomenclatures.find(N => N.mnemonique === 'TYPE_MEDIA')[
      'values'
    ]) {
      nomenclatures[nomenclature.id_nomenclature] = nomenclature;
    }
    return nomenclatures;
  }

  getNomenclatures(): Observable<any> {
    if (this.nomenclatures) return of(this.nomenclatures);
    return this._dataFormService.getNomenclatures(_NOMENCLATURES).pipe(
      switchMap(nomenclatures => {
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
      .filter(N => !nomenclatureType || N.mnemonique === nomenclatureType)
      .map(N => N.values.find(n => n[fieldName] === value))
      .filter(n => n);
    return res && res.length == 1 ? res[0] : null;
  }

  getMedias(uuidAttachedRow): Observable<any> {
    return this._http.get(`${AppConfig.API_ENDPOINT}/gn_commons/medias/${uuidAttachedRow}`);
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
      responseType: 'json'
    });
    const id_request = String(Math.random());
    return this._http.request(req);
  }

  deleteMedia(idMedia) {
    return this._http.delete(`${AppConfig.API_ENDPOINT}/gn_commons/media/${idMedia}`);
  }

  getIdTableLocation(schemaDotTable): Observable<number> {
    let idTableLocation = this.idTableLocations[schemaDotTable];
    if (idTableLocation) {
      return of(idTableLocation);
    } else {
      return this._http
        .get<any>(`${AppConfig.API_ENDPOINT}/gn_commons/get_id_table_location/${schemaDotTable}`)
        .pipe()
        .switchMap(idTableLocation => {
          this.idTableLocations[schemaDotTable] = idTableLocation;
          return of(idTableLocation);
        });
    }
  }

  validMedias(medias) {
    return (
      !medias ||
      !medias.length ||
      medias.every(mediaData => {
        const media = new Media(mediaData);
        return media.valid();
      })
    );
  }

  validOrLoadingMedias(medias) {
    return (
      !medias ||
      !medias.length ||
      medias.every(mediaData => {
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
    return media.href(thumbnail);
  }

  embedHref(media) {
    if (!(media instanceof Media)) {
      media = new Media(media);
    }
    if (['Vidéo Youtube'].includes(this.typeMedia(media))) {
      const v_href = media.href().split('/');
      const urlLastPart = v_href[v_href.length - 1];
      const videoId = urlLastPart.includes('?')
        ? urlLastPart.includes('v=')
          ? urlLastPart
              .split('?')
              .find(s => s.includes('v='))
              .replace('v=', '')
          : urlLastPart.split('?')[0]
        : urlLastPart;
      return `https://www.youtube.com/embed/${videoId}`;
    }
    if (['Vidéo Dailymotion'].includes(this.typeMedia(media))) {
      const v = media.href().split('/');
      const videoId = v[v.length - 1].split('?')[0];
      return `https://www.dailymotion.com/embed/video/${videoId}`;
    }

    if (['Vidéo Vimeo'].includes(this.typeMedia(media))) {
      const v = media.href().split('/');
      const videoId = v[v.length - 1].split('?')[0];
      return `https://player.vimeo.com/video/${videoId}`;
    }

    return media.href();
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
    return `<a target="_blank" href="${media.href()}">${media.title_fr}</a> : ${
      media.description_fr
    } (${this.getNomenclature(media.id_nomenclature_media_type).label_fr}, ${media.author})`;
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
    href=${media.href()}
    title='${this.toString(media)}'
    target='_blank'
    style='margin: 0 2px'
    >`;
    if (this.typeMedia(media) === 'Photo') {
      tooltip += `<img style='
      height: 50px; width: 50px; border-radius: 25px; object-fit: cover;
      '
      src='${media.href(50)}' alt='${media.title_fr}' >`; // TODO PARAMETERS => taille des thumbnails
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

  //Fonction permettant d'ajouter les informations d'un champ aditionnel dans un ElementHTML (pas forcément de type média) 
  createVisualizeElement(container : HTMLElement, widget, values) {
    if(!container){
      return;
    }
    //même si c'est vide, on va quand même afficher le contenu
    if(values.additional_fields[widget.attribut_name]){
      //FINALEMENT on passera jamais ici car les médias sont maintenant gérés dans le champs média du dénombrement (counting)
      //Bien sur petite exception pour le type médias
      if (widget.type_widget == 'medias'){
        //pour tous les médias présent par type de widget medias
        values.additional_fields[widget.attribut_name].forEach((media, i) => {
          //On duplique la première div pour récupérer le style qui va bien
          let newDiv = container.firstChild.cloneNode(true) as HTMLElement;
          //On réécrit son contenu
          newDiv.innerHTML = widget.attribut_label + ' (' + (i+1) + '/' + values.additional_fields[widget.attribut_name].length + ') ';
          
          //On lui ajoute la balise a
          let ahref = document.createElement("a");
          ahref.href = this.href(media);
          ahref.target = 'blank';
          ahref.innerHTML = media.title_fr;
          newDiv.appendChild(ahref);

          //On lui ajoute la balise i
          let info = document.createElement("i");
          info.innerHTML = " (" + this.typeMedia(media) + (media.author? ", " + media.author : "") + ") ";
          newDiv.appendChild(info);

          //On lui ajoute la balise span
          if(media.description_fr){
            let span = document.createElement("span");
            span.innerHTML = media.description_fr;
            newDiv.appendChild(span);
          }

          //On lui ajoute la miniature
          let visuMedia = document.createElement("div");
          //Il faut récupérer l'attribut ng pour la div afin qu'il utilise bien le css
          visuMedia.className = "flex-container";
          if(newDiv.attributes[0]){
            visuMedia.setAttribute(newDiv.attributes[0].name, '');
          }
          switch(this.typeMedia(media)){
            case 'PDF':
              visuMedia.innerHTML = "<embed src='" + media.safeUrl + "' width='100%' height='200' type='application/pdf' />";
              //let visualizer = 
              break;
            case 'Vidéo Youtube':
            case 'Vidéo Dailymotion':
            case 'Vidéo Vimeo':
              visuMedia.innerHTML = "<iframe width='100%' height='200' src='" + media.safeEmbedUrl + "' allowfullscreen ></iframe>";
              break;
            case 'Vidéo (fichier)':
              visuMedia.innerHTML = "<video class='media-center' controls src='" + this.href(media) + "'></video>";
              break;
            case 'Audio':
              visuMedia.innerHTML = "<audio class='media-center' controls src='" + this.href(media) + "'></audio>";
              break;
            case 'Photo':
              visuMedia.innerHTML = "<img class='media-center' src='" + this.href(media, 200) + "' alt='" + media.title_fr + "'/>";
              break;
          }
          
          newDiv.appendChild(visuMedia);
          newDiv.className ='additional_field';
          container.appendChild(newDiv);
        })
      }else{
        //à condition qu'il est un label (donc pas les types html)
        let newDiv = container.firstChild.cloneNode(true)  as HTMLElement;
        switch(widget.type_widget){
          case 'html':
            //on affiche rien
            break;
          case 'date':
            newDiv.getElementsByClassName('label')[0].innerHTML = widget.attribut_label + ' :';
            if(typeof values.additional_fields[widget.attribut_name] == "object"){
              newDiv.getElementsByClassName('value')[0].innerHTML = this.dateParser.format(
                values.additional_fields[widget.attribut_name]
              );
            }else{
              newDiv.getElementsByClassName('value')[0].innerHTML = values.additional_fields[widget.attribut_name];
            }
            newDiv.className ='additional_field';
            container.appendChild(newDiv);
            break;
          /*case 'nomenclature':
            this._dataFormService.getNomenclatures([widget.code_nomenclature_type]).subscribe(
              (nomenclature) => {
                newDiv.getElementsByClassName('label')[0].innerHTML = widget.attribut_label + ' :';
                const res = nomenclature
                  .map(N => N.values.find(n => n['id_nomenclature'] === values.additional_fields[widget.attribut_name]))
                  .filter(n => n);
                if(res && res.length == 1){
                  newDiv.getElementsByClassName('value')[0].innerHTML = res[0].label_fr;
                }else{
                  newDiv.getElementsByClassName('value')[0].innerHTML = " - ";
                }
                newDiv.className ='additional_field';
                container.appendChild(newDiv);
              }
            );
            break;*/
          default:
            newDiv.getElementsByClassName('label')[0].innerHTML = widget.attribut_label + ' :';
            newDiv.getElementsByClassName('value')[0].innerHTML = values.additional_fields[widget.attribut_name];
            newDiv.className ='additional_field';
            container.appendChild(newDiv);
            break;
        }
        //si ce n'est pas un média, on affiche son libellé (configuration) et sa valeur (bdd)
        /*let newDiv = container.firstChild.cloneNode(true)  as HTMLElement;
        newDiv.getElementsByClassName('label')[0].innerHTML = widget.attribut_label + ' :';
        newDiv.getElementsByClassName('value')[0].innerHTML = values.additional_fields[widget.attribut_name];
        newDiv.className ='additional_field';
        container.appendChild(newDiv);*/
      }
    }else{
      if (widget.attribut_label){
        let newDiv = container.firstChild.cloneNode(true)  as HTMLElement;
        newDiv.getElementsByClassName('label')[0].innerHTML = widget.attribut_label + ' :';
        newDiv.getElementsByClassName('value')[0].innerHTML = " - ";
        newDiv.className ='additional_field';
        container.appendChild(newDiv);
      }
    }
  }
}
