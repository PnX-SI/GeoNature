import { Injectable } from '@angular/core';
import {
  HttpClient,
  HttpParams,
  HttpEventType,
  HttpErrorResponse,
  HttpEvent
} from '@angular/common/http';
import { AppConfig } from '../../../conf/app.config';
import { Taxon } from './taxonomy/taxonomy.component';
import { Observable } from 'rxjs';

/** Interface for queryString parameters*/
interface ParamsDict {
  [key: string]: any;
}

export const FormatMapMime = new Map([
  ['csv', 'text/csv'],
  ['json', 'application/json'],
  ['shp', 'application/zip']
]);

@Injectable()
export class DataFormService {
  private _blob: Blob;
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

  getNomenclatures(codesNomenclatureType) {
    let params: HttpParams = new HttpParams();
    params = params.set('orderby', 'label_default');
    codesNomenclatureType.forEach(code => {
      params = params.append('code_type', code);
    });

    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/nomenclatures/nomenclatures`, {
      params: params
    });
  }

  getDefaultNomenclatureValue(path, mnemoniques: Array<string> = [], kwargs: ParamsDict = {}) {
    let queryString: HttpParams = new HttpParams();
    // tslint:disable-next-line:forin
    for (const key in kwargs) {
      queryString = queryString.set(key, kwargs[key].toString());
    }
    mnemoniques.forEach(mnem => {
      queryString = queryString.append('mnemonique', mnem);
    });
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/${path}/defaultNomenclatures`, {
      params: queryString
    });
  }

  getDatasets(params?: ParamsDict, orderByName = true) {
    let queryString: HttpParams = new HttpParams();
    if (orderByName) {
      queryString = this.addOrderBy(queryString, 'dataset_name');
    }

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

  getObserversFromCode(codeList) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/menu_from_code/${codeList}`);
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

  getTypologyHabitat(id_list: number) {
    let params = new HttpParams();

    if (id_list) {
      params = params.set('id_list', id_list.toString());
    }
    return this._http
      .get<any>(`${AppConfig.API_ENDPOINT}/habref/typo`, { params: params })
      .map(data => {
        // replace '_' with space because habref is super clean !
        return data.map(d => {
          d['lb_nom_typo'] = d['lb_nom_typo'].replace(/_/g, ' ');
          return d;
        });
      });
  }

  getHabitatInfo(cd_hab) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/habref/habitat/${cd_hab}`);
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

  getAreaSize(geojson) {
    return this._http.post<number>(`${AppConfig.API_ENDPOINT}/geo/area_size`, geojson);
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

  getAreas(area_type_list: Array<number>, area_name?) {
    let params: HttpParams = new HttpParams();

    area_type_list.forEach(id_type => {
      params = params.append('id_type', id_type.toString());
    });

    if (area_name) {
      params = params.set('area_name', area_name);
    }

    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/geo/areas`, { params: params });
  }

  /**
   *
   * @param params: dict of paramters
   * @param orderByName :default true
   */
  getAcquisitionFrameworks(params?: ParamsDict, orderByName = true) {
    let queryString: HttpParams = new HttpParams();
    if (orderByName) {
      queryString = this.addOrderBy(queryString, 'acquisition_framework_name');
    }
    if (params) {
      // tslint:disable-next-line:forin
      for (let key in params) {
        if (params[key] !== null) {
          queryString = queryString.set(key, params[key]);
        }
      }
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/acquisition_frameworks`, {
      params: queryString
    });
  }

  getAcquisitionFramework(id_af) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/acquisition_framework/${id_af}`);
  }

  getOrganisms(orderByName = true) {
    let queryString: HttpParams = new HttpParams();
    if (orderByName) {
      queryString = this.addOrderBy(queryString, 'nom_organisme');
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/organisms`, {
      params: queryString
    });
  }

  getOrganismsDatasets(orderByName = true) {
    let queryString: HttpParams = new HttpParams();
    if (orderByName) {
      queryString = this.addOrderBy(queryString, 'nom_organisme');
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/organisms_dataset_actor`, {
      params: queryString
    });
  }

  getRole(id: number) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/role/${id}`);
  }

  getRoles(params?: ParamsDict, orderByName = true) {
    let queryString: HttpParams = new HttpParams();
    if (orderByName) {
      queryString = this.addOrderBy(queryString, 'nom_role');
    }
    // tslint:disable-next-line:forin
    for (let key in params) {
      if (params[key] !== null) {
        queryString = queryString.set(key, params[key]);
      }
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/roles`, { params: queryString });
  }

  getDataset(id) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/dataset/${id}`);
  }

  getModulesList(exclude: Array<string>) {
    let queryString: HttpParams = new HttpParams();
    exclude.forEach(mod_code => {
      queryString = queryString.append('exclude', mod_code);
    });
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/gn_commons/modules`, {
      params: queryString
    });
  }

  getModuleByCodeName(module_code) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/gn_commons/modules/${module_code}`);
  }

  getCruved(modules_code?: Array<string>) {
    let queryString: HttpParams = new HttpParams();
    if (modules_code) {
      modules_code.forEach(mod_code => {
        queryString = queryString.append('module_code', mod_code);
      });
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/permissions/cruved`, {
      params: queryString
    });
  }

  addOrderBy(httpParam: HttpParams, order_column): HttpParams {
    return httpParam.append('orderby', order_column);
  }

  subscribeAndDownload(
    source: Observable<HttpEvent<Blob>>,
    fileName: string,
    format: string
  ): void {
    const subscription = source.subscribe(
      event => {
        if (event.type === HttpEventType.Response) {
          this._blob = new Blob([event.body], { type: event.headers.get('Content-Type') });
        }
      },
      (e: HttpErrorResponse) => {
        //this._commonService.translateToaster('error', 'ErrorMessage');
        //this.isDownloading = false;
      },
      // response OK
      () => {
        //this.isDownloading = false;
        const date = new Date();
        const extension = format === 'shapefile' ? 'zip' : format;
        this.saveBlob(this._blob, `${fileName}_${date.toISOString()}.${extension}`);
        subscription.unsubscribe();
      }
    );
  }

  saveBlob(blob, filename) {
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.setAttribute('visibility', 'hidden');
    link.download = filename;
    link.onload = () => {
      URL.revokeObjectURL(link.href);
    };
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }
}
