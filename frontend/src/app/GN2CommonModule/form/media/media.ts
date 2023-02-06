import { Subscription } from 'rxjs';
import { SafeResourceUrl } from '@angular/platform-browser';
import { ConfigService } from '@geonature/services/config.service';

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
    return [
      'id_media',
      'id_table_location',
      'author',
      'uuid_attached_row',
      'unique_id_media',
      'title_fr',
      'description_fr',
      'media_url',
      'id_nomenclature_media_type',
      'bFile',
      'file',
    ].every((key) => this[key] === values[key]);
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
      data[key] = this[key];
    }
    return data;
  }

  href(API_ENDPOINT: string, MEDIA_URL: string, thumbnailHeight = null): string {
    if (thumbnailHeight) {
      let filePath = `gn_commons/media/thumbnails/${this.id_media}/${thumbnailHeight}`;
      return `${API_ENDPOINT}/${filePath}`;
    }
    return this.media_path
      ? `${API_ENDPOINT}/${MEDIA_URL}/attachments/${this.media_path}`
      : this.media_url;
  }

  valid(): boolean {
    return !!this.sent;
  }
}

export { Media };
