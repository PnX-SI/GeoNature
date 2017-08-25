import { Injectable } from '@angular/core';
import { Http } from '@angular/http';
import 'rxjs/add/operator/toPromise';
import { AppConfigs } from '../../../../conf/app.configs'

@Injectable()
export class FormService {
  taxon: any;
  constructor(private _http: Http) {
    this.taxon= {};
   }

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

  getObservers(idMenu) {
     return this._http.get(`${AppConfigs.API_ENDPOINT}users/menu/${idMenu}`).
      toPromise()
      .then(response => {
        return response.json();
      });
  }
  
  searchTaxonomy (taxonName: string,id: string) {
    return this._http.get(`${AppConfigs.API_TAXHUB}taxref/allnamebylist/${id}?search_name=${taxonName}`)
    .map(res => res.json());
  }

}
