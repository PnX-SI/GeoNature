import { Subscription } from 'rxjs';
import { AppConfig } from '@geonature_config/app.config';

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

  public bLoading: boolean=false;
  public uploadPercentDone:number = 0;
  public pendingRequest: Subscription; // pour pouvoir couper l'upload si on supprime le media pendant l'upload

  constructor(values = {}) {
    this.setValues(values)
  }

  setValues(values: Object) {
    for (const key of Object.keys(values)) {
      this[key] = values[key];
    }
  }

  href(): string {
    return this.media_path
      ? `${AppConfig.API_ENDPOINT}/${this.media_path}`
      : this.media_url
  }

  valid(): boolean {
    return !!(this.title_fr && this.description_fr && this.href());
  }

  readyForUpload(): boolean {
    return !!(this.title_fr && this.description_fr && !this.bLoading)
  }

}

export { Media }
