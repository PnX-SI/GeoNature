import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import 'rxjs/add/operator/toPromise';
import { AppConfig } from '../../../conf/app.config';
import { Observable } from 'rxjs/Rx';
import { Taxon } from './taxonomy/taxonomy.component';

@Injectable()
export class DataFormService {
  constructor(private _http: HttpClient) {}

  getNomenclature(id_nomenclature: number, regne?: string, group2_inpn?: string) {
    let params: HttpParams = new HttpParams();
    regne ? (params = params.set('regne', regne)) : (params = params.set('regne', ''));
    group2_inpn
      ? (params = params.set('group2_inpn', group2_inpn))
      : (params = params.set('group2_inpn', ''));
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/nomenclatures/nomenclature/${id_nomenclature}`,
      { params: params }
    );
  }

  getNomenclatures(...id_nomenclatures) {
    let params: HttpParams = new HttpParams();
    id_nomenclatures.forEach(id => {
      params = params.append('id_type', id);
    });
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/nomenclatures/nomenclatures`, {
      params: params
    });
  }

  getDatasets(idOrganism?) {
    let params: HttpParams = new HttpParams();
    if (idOrganism) {
      params = params.set('organisme', idOrganism);
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/datasets`, {
      params: params
    });
  }

  getObservers(idMenu) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/menu/${idMenu}`);
  }

  searchTaxonomy(taxonName: string, idList: string, regne?: string, groupe2Inpn?: string) {
    let params: HttpParams = new HttpParams();
    params = params.set('search_name', taxonName);
    if (regne) {
      params = params.set('regne', regne);
    }
    if (groupe2Inpn) {
      params = params.set('group2_inpn', groupe2Inpn);
    }
    return this._http.get<Taxon[]>(`${AppConfig.API_TAXHUB}/taxref/allnamebylist/${idList}`, {
      params: params
    });
  }

  getTaxonInfo(cd_nom: number) {
    return this._http.get<Taxon>(`${AppConfig.API_TAXHUB}/taxref/${cd_nom}`);
  }

  getRegneAndGroup2Inpn() {
    return this._http.get<any>(`${AppConfig.API_TAXHUB}/taxref/regnewithgroupe2`);
  }

  getGeoInfo(geojson) {
    return this._http.post<any>(`${AppConfig.API_ENDPOINT}/geo/info`, geojson);
  }

  getGeoIntersection(geojson, idType?) {
    if (idType) {
      geojson['id_type'] = idType;
    }
    return this._http.post(`${AppConfig.API_ENDPOINT}/geo/areas`, geojson);
  }

  getFormatedGeoIntersection(geojson, idType?) {
    if (idType) {
      geojson['id_type'] = idType;
    }
    return this._http.post(`${AppConfig.API_ENDPOINT}/geo/areas`, geojson).map(res => {
      const areasIntersected = [];
      Object.keys(res).forEach(key => {
        const typeName = res[key]['type_name'];
        const areas = res[key]['areas'];
        const formatedAreas = areas.map(area => area.area_name).join(', ');
        const obj = {
          type_name: typeName,
          areas: formatedAreas
        };
        areasIntersected.push(obj);
      });
      return areasIntersected;
    });
  }
}
