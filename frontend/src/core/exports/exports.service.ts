import { Injectable } from '@angular/core';
import { Http, URLSearchParams } from '@angular/http';
import { AppConfig } from '../../conf/app.config';

@Injectable()
export class ExportsService {

  constructor(private _api: Http) {
    
   }

   getFakeViewList() {
     return [
       {
         'id_view':1,
         'view_name': "Export au format 'Standard d'occurrences de taxons' "
       }
     ];
   }
   getViewList() {
    return this._api.get(`${AppConfig.API_ENDPOINT}export/viewList`)
      .map(data => data.json());
   }
}