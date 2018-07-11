import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import 'rxjs/add/operator/toPromise';
import { AppConfig } from '../../../conf/app.config';
import { Observable } from 'rxjs/Rx';
import { Taxon } from './taxonomy/taxonomy.component';

@Injectable()
export class DataFormService {
  constructor(private _http: HttpClient) {}

  getNomenclature(
    codeNomenclatureType: string,
    regne?: string,
    group2_inpn?: string,
    filters?: any
  ) {
    let params: HttpParams = new HttpParams();
    regne ? (params = params.set('regne', regne)) : (params = params.set('regne', ''));
    group2_inpn
      ? (params = params.set('group2_inpn', group2_inpn))
      : (params = params.set('group2_inpn', ''));
    if (filters['orderby']) {
      params = params.set('orderby', filters['orderby']);
    }
    if (filters['order']) {
      params = params.set('order', filters['order']);
    }
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/nomenclatures/nomenclature/${codeNomenclatureType}`,
      { params: params }
    );
  }

  getNomenclatures(...codesNomenclatureType) {
    let params: HttpParams = new HttpParams();
    codesNomenclatureType.forEach(code => {
      params = params.append('code_type', code);
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

  async getTaxonInfoSynchrone(cd_nom: number): Promise<any> {
    const response = await this._http
      .get<Taxon>(`${AppConfig.API_TAXHUB}/taxref/${cd_nom}`)
      .toPromise();
    return response;
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

  getMunicipalities(nom_com?, limit?) {
    let params: HttpParams = new HttpParams();

    if (nom_com) {
      params = params.set('nom_com', nom_com);
    }
    if (limit) {
      params = params.set('limit', limit);
    }

    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/geo/municipalities`, { params: params });
  }

  getAcquisitionFrameworks() {
    return this._http.get(`${AppConfig.API_ENDPOINT}/meta/acquisition_frameworks`);
  }

  getOrganisms() {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/organisms`);
  }

  getRoles() {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/roles`);
  }

  getDataset(id) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/dataset/${id}`);
  }
}
