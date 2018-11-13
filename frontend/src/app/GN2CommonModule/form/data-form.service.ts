import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import 'rxjs/add/operator/toPromise';
import { AppConfig } from '../../../conf/app.config';
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

  getDatasets(params?) {
    let queryString: HttpParams = new HttpParams();
    if (params) {
      for (const key in params) {
        if (key === 'idOrganism') {
          queryString = queryString.set('organisme', params[key]);
          // is its an array of id_af
        } else if (key === 'id_acquisition_frameworks') {
          params[key].forEach(id_af => {
            queryString = queryString.append('id_acquisition_framework', id_af);
          });
        } else {
          queryString = queryString.set(key, params[key].toString());
        }
      }
    }

    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/datasets`, {
      params: queryString
    });
  }

  getObservers(idMenu) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/menu/${idMenu}`);
  }

  autocompleteTaxon(api_endpoint: string, searh_name: string, params?: { [key: string]: string }) {
    let queryString: HttpParams = new HttpParams();
    queryString = queryString.set('search_name', searh_name);
    for (let key in params) {
      if (params[key]) {
        queryString = queryString.set(key, params[key]);
      }
    }
    return this._http.get<Taxon[]>(`${api_endpoint}`, {
      params: queryString
    });
  }

  getTaxonInfo(cd_nom: number) {
    return this._http.get<Taxon>(`${AppConfig.API_TAXHUB}/taxref/${cd_nom}`);
  }

  getTaxonAttributsAndMedia(cd_nom: number, id_attributs?: Array<number>) {
    let query_string = new HttpParams();
    if (id_attributs) {
      id_attributs.forEach(id => {
        query_string = query_string.append('id_attribut', id.toString());
      });
    }

    return this._http.get<any>(`${AppConfig.API_TAXHUB}/bibnoms/taxoninfo/${cd_nom}`, {
      params: query_string
    });
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

  getTaxhubBibAttributes() {
    return this._http.get<any>(`${AppConfig.API_TAXHUB}/bibattributs/`);
  }

  getTaxonomyLR() {
    return this._http.get<any>(`${AppConfig.API_TAXHUB}/taxref/bib_lr`);
  }

  getTaxonomyHabitat() {
    return this._http.get<any>(`${AppConfig.API_TAXHUB}/taxref/bib_habitats`);
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

  getAreas(id_type?, area_name?) {
    let params: HttpParams = new HttpParams();

    if (id_type) {
      params = params.set('id_type', id_type);
    }

    if (area_name) {
      params = params.set('area_name', area_name);
    }

    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/geo/areas`, { params: params });
  }

  getAcquisitionFrameworks() {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/acquisition_frameworks`);
  }

  getAcquisitionFramework(id_af) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/acquisition_framework/${id_af}`);
  }

  getOrganisms() {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/organisms`);
  }

  getRoles(params?: any) {
    let queryString: HttpParams = new HttpParams();
    // tslint:disable-next-line:forin
    for (let key in params) {
      if (params[key] !== null) {
        queryString = queryString.set(key, params[key]);
      }
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/roles`, { params: queryString } );
  }

  getDataset(id) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/dataset/${id}`);
  }

  getModulesList() {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/gn_commons/modules`);
  }

}
