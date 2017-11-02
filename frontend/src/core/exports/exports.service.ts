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
         'view_name': "Données du contact faune/flore au format 'Standard d'occurrence de taxon' "
       },
       {
        'id_view': 2,
        'view_name': 'Export test'
      },
      {
        'id_view': 2,
        'view_name': 'Export test'
      }
     ]
   }
   getViewList() {
    return this._api.get(`${AppConfig.API_ENDPOINT}export/viewList`)
      .map(data => data.json());
   }
}