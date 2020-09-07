import { Subscription } from 'rxjs';
import { AppConfig } from '@geonature_config/app.config';
import { SafeResourceUrl } from '@angular/platform-browser';

class Media {

  // media data
  public id_media: number;
  public id_table_location: number;
  public uuid_attached_row: string;
  public unique_id_media: string;
  public title_fr: string;
  public description_fr: string;
  public media_url: string;
  public media_path: string;
  public id_nomenclature_media_type: number;
  public author: string;

  public bFile: boolean;
  public bLoading: boolean = false;
  public uploadPercentDone: number = 0;
  public pendingRequest: Subscription; // pour pouvoir couper l'upload si on supprime le media pendant l'upload


  public safeUrl: SafeResourceUrl;
  public safeEmbedUrl: SafeResourceUrl;


  public details: boolean;
  public sent: boolean;

  constructor(values = {}) {
    this.setValues(values);
  }

  hasValue(values) {
    return ['id_media',
    'id_table_location',
    'author',
    'uuid_attached_row',
    'unique_id_media',
    'title_fr',
    'description_fr',
    'media_url',
    'id_nomenclature_media_type',
    'bFile',
    'file']
      .every(key => this[key] === values[key]);
  }

  setValues(values: Object) {
    for (const key of Object.keys(values)) {
      this[key] = values[key];
    }
    this.sent = this.sent !== undefined ? this.sent : !!this.id_media;
  }

  data() {
    const data = {};
    for (const key of Object.keys(this)) {
      if (['pendingRequest'].includes(key)) continue;
      data[key] = this[key]
    }
    return data
  }



  filePath(thumbnailHeight = null) {
    let filePath;
    if (this.media_path) {
      filePath = this.media_path;
    } else if (this.media_url) {
      const v_url = this.media_url.split('/')
      const fileName = v_url[v_url.length - 1];
      filePath = `${AppConfig.UPLOAD_FOLDER}/${this.id_table_location}/${this.id_media}_${fileName}`;
    }

    if (thumbnailHeight && filePath) {
      filePath = filePath.replace(AppConfig.UPLOAD_FOLDER, `${AppConfig.UPLOAD_FOLDER}/thumbnails`);
      filePath = filePath.replace('.', `_thumbnail_${thumbnailHeight}.`);
    }

    return filePath;
  }

  href(thumbnailHeight = null): string {
    if (thumbnailHeight) {
      return `${AppConfig.API_ENDPOINT}/${this.filePath(thumbnailHeight)}`;
    }
    return this.media_path
      ? `${AppConfig.API_ENDPOINT}/${this.media_path}`
      : this.media_url
  }

  valid(): boolean {
    return !!(this.sent);
  }

}

export { Media }
