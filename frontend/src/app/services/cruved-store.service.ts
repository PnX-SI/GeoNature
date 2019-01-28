import { Injectable } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';

@Injectable()
export class CruvedStoreService {
  public cruved: any;
  constructor(private _api: DataFormService) {
    this._api.getCruved().subscribe(data => {
      this.cruved = data;
    });
  }
}
