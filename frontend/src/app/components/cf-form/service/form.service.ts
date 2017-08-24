import { Injectable } from '@angular/core';
import { Http } from '@angular/http';
import 'rxjs/add/operator/toPromise';
import { AppConfigs } from '../../../../conf/app.configs'

@Injectable()
export class FormService {
  taxonomy: any;
  constructor(private _http: Http) { }

  getNomenclature(id_nomenclature: number, regne?:string, group2_inpn?: string){
    console.log(AppConfigs.API_ENDPOINT);
    const params = {id: id_nomenclature, regne: regne, group2_inpn:group2_inpn};
    if (regne) {
      params.regne = regne;
    }
    if (group2_inpn) {
      params.group2_inpn = group2_inpn;
    }
    return this._http.get(`${AppConfigs.API_ENDPOINT}nomenclatures/nomenclature/${id_nomenclature}`)
    .toPromise()
    .then(
      response => {
        return response.json();
      });
    }

  getTaxonomy () {
    return [
      {
        cd_nom: 5422,
        taxonName: 'Abietinella abietina (Hedw.) M.Fleisch.',
        groupe2INPN: 'Algues'
      },
      {
        cd_nom: 1111,
        taxonName: 'Geotriton fuscus Bonaparte, 1837',
        groupe2INPN: 'Amphibiens'
      },
        {
        cd_nom: 2222,
        taxonName: 'Hemitriton asper Dugès, 1852',
        groupe2INPN: 'Amphibiens'
      }
    ];
  }

  getObservers(idMenu) {
     return this._http.get(`${AppConfigs.API_ENDPOINT}users/menu/${idMenu}`).
      toPromise()
      .then(response => {
        return response.json();
      });
  }

}
