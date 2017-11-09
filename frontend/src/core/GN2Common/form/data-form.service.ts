import { Injectable } from '@angular/core';
import { Http, URLSearchParams } from '@angular/http';
import 'rxjs/add/operator/toPromise';
import { AppConfig } from '../../../conf/app.config';

@Injectable()
export class DataFormService {

  constructor(private _http: Http) {
   }

  getNomenclature(id_nomenclature: number, regne?: string, group2_inpn?: string) {
    const params: URLSearchParams = new URLSearchParams();
    regne ? params.set('regne', regne) : params.set('regne', '');
    group2_inpn ? params.set('group2_inpn', group2_inpn) : params.set('group2_inpn', '');
    return this._http.get(`${AppConfig.API_ENDPOINT}nomenclatures/nomenclature/${id_nomenclature}`, {search: params})
    .map(response => response.json());
    }

  getNomenclatures(...id_nomenclatures) {
    const params: URLSearchParams = new URLSearchParams();
    id_nomenclatures.forEach(id => {
      params.append('id_type', id);
    });
    return this._http.get(`${AppConfig.API_ENDPOINT}nomenclatures/nomenclatures`, {search: params})
      .map(response => response.json());
  }

  getDatasets(idOrganism?) {
    const params: URLSearchParams = new URLSearchParams();
    if (idOrganism) {
      params.set('organism', idOrganism);
    }
    return this._http.get(`${AppConfig.API_ENDPOINT}meta/datasets`, {search: params} )
      .map(response => response.json());
  }

  getObservers(idMenu) {
     return this._http.get(`${AppConfig.API_ENDPOINT}users/menu/${idMenu}`)
      .map(response => response.json());
  }

  searchTaxonomy(taxonName: string, id: string, regne?: string, groupe2Inpn?: string) {
    const params: URLSearchParams = new URLSearchParams();
    params.append('search_name', taxonName);
    if (regne) {
      params.append('regne', regne);
    }
    if (groupe2Inpn) {
      params.append('group2_inpn', groupe2Inpn);
    }
    return this._http.get(`${AppConfig.API_TAXHUB}taxref/allnamebylist/${id}`, { search : params})
    .map(res => res.json());
  }

  getTaxonInfo(cd_nom: number) {
   return this._http.get(`${AppConfig.API_TAXHUB}taxref/${cd_nom}`)
    .map(res => res.json());
  }

  getRegneAndGroup2Inpn() {
    return this._http.get(`${AppConfig.API_TAXHUB}taxref/regnewithgroupe2`)
    .map(res => res.json());
  }

  getGeoInfo(geojson) {
    return this._http.post(`${AppConfig.API_ENDPOINT}geo/info`, geojson)
      .map(response => response.json());
  }

  getGeoIntersection(geojson, idType?) {
    if (idType) {
      geojson['id_type'] = idType;
    }
    return this._http.post(`${AppConfig.API_ENDPOINT}geo/areas`, geojson)
    .map(response => response.json());
  }

  getFormatedGeoIntersection(geojson, idType?) {
    if (idType) {
      geojson['id_type'] = idType;
    }
    return this._http.post(`${AppConfig.API_ENDPOINT}geo/areas`, geojson)
    .map(response => {
      const res = response.json();
      const areasIntersected = [];
      Object.keys(res).forEach(key => {
        const typeName = res[key]['type_name'];
        const areas = res[key]['areas'];
        const formatedAreas = areas.map(area => area.area_name).join(', ');
        const obj = {'type_name': typeName, 'areas': formatedAreas }
        areasIntersected.push(obj);
      });
      return areasIntersected;
    });

  }

  postContact(form) {
    return this._http.post(`${AppConfig.API_ENDPOINT}contact/releve`, form)
      .map(response => {
        if (response.status !== 200) {
          throw new Error('Post Error');
        }else {
          return response.json();
        }
      });
  }

}
