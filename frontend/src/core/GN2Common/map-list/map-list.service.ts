import { Injectable} from '@angular/core';
import { Subject } from 'rxjs/Subject';
import { Http, URLSearchParams } from '@angular/http';
import { AppConfig } from '../../../conf/app.config';

@Injectable()
export class MapListService {
    // mapListData: MapListData[];
    constructor(private _http: Http) {
  }

getReleves() {
    return this._http.get(`${AppConfig.API_ENDPOINT}contact/releves`)
      .map(res => res.json())
      .map(res => res.features);
    //   .map(res => {
    //         res.forEach(el => {
    //         console.log(el);
    //         console.log(el.properties.occurrences.nom_cite);
    //         mapdata.idReleve = el.properties.id_releve_contact;
    //         mapdata.taxons = el.properties.occurrences.nom_cite;
    //         // mapdata.observer  = el.properties.observers;
    //         this.mapListData.push(mapdata);
    //         });
    //     return this.mapListData;
    // }
    //   );
  }
}

// export interface MapListData {
//   idReleve: string; // id_releve_contact
//   taxons: string; // nom_cite
//   observer: []; // nom_role + prenom_role
//   date: string; // meta_create_date
//   dataSet: string;
// }
