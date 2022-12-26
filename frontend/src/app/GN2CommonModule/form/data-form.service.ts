import { Injectable } from '@angular/core';
import {
  HttpClient,
  HttpParams,
  HttpEventType,
  HttpErrorResponse,
  HttpHeaders,
  HttpEvent,
} from '@angular/common/http';
import { AppConfig } from '../../../conf/app.config';
import { Taxon } from './taxonomy/taxonomy.component';
import { Observable } from 'rxjs';
import { isArray } from 'rxjs/internal-compatibility';
import { map } from 'rxjs/operators';

/** Interface for queryString parameters*/
interface ParamsDict {
  [key: string]: any;
}

export const FormatMapMime = new Map([
  ['csv', 'text/csv'],
  ['json', 'application/json'],
  ['shp', 'application/zip'],
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
    if (filters['cd_nomenclature'] && filters['cd_nomenclature'].length > 0) {
      filters['cd_nomenclature'].forEach((cd) => {
        params = params.append('cd_nomenclature', cd);
      });
    }
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/nomenclatures/nomenclature/${codeNomenclatureType}`,
      { params: params }
    );
  }

  getNomenclatures(codesNomenclatureType: Array<string>) {
    let params: HttpParams = new HttpParams();
    params = params.set('orderby', 'label_default');
    codesNomenclatureType.forEach((code) => {
      params = params.append('code_type', code);
    });

    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/nomenclatures/nomenclatures`, {
      params: params,
    });
  }

  getDefaultNomenclatureValue(path, mnemoniques: Array<string> = [], kwargs: ParamsDict = {}) {
    let queryString: HttpParams = new HttpParams();
    // eslint-disable-next-line guard-for-in
    for (const key in kwargs) {
      queryString = queryString.set(key, kwargs[key].toString());
    }
    mnemoniques.forEach((mnem) => {
      queryString = queryString.append('mnemonique', mnem);
    });
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/${path}/defaultNomenclatures`, {
      params: queryString,
    });
  }

  getDatasets(params?: ParamsDict, orderByName = true, fields = []) {
    let queryString: HttpParams = new HttpParams();
    queryString = this.addOrderBy(queryString, 'dataset_name');
    fields.forEach((f) => {
      queryString = queryString.append('fields', f);
    });

    if (params) {
      for (const key in params) {
        if (key === 'idOrganism') {
          queryString = queryString.set('organisme', params[key]);
          // is its an array of id_af
        } else if (key === 'id_acquisition_frameworks') {
          params[key].forEach((id_af) => {
            queryString = queryString.append('id_acquisition_framework', id_af);
          });
        } else {
          queryString = queryString.set(key, params[key].toString());
        }
      }
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/datasets`, {
      params: queryString,
    });
  }

  /**
   * Get dataset list for metadata modules
   */
  // getAfAndDatasetListMetadata(searchTerms) {

  //   let queryString = new HttpParams();
  //   for (let key in searchTerms) {
  //     queryString = queryString.set(key, searchTerms[key])
  //   }

  //   return this._http.get<any>(
  //     `${AppConfig.API_ENDPOINT}/meta/af_datasets_metadata`,
  //     { params: queryString }
  //   );
  // }

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
      params: queryString,
    });
  }

  getTaxonInfo(cd_nom: number, areasStatus?: Array<string>) {
    let query_string = new HttpParams();
    if (areasStatus) {
      query_string = query_string.append('areas_status', areasStatus.join(','));
    }
    return this._http.get<Taxon>(`${AppConfig.API_TAXHUB}/taxref/${cd_nom}`, {
      params: query_string,
    });
  }

  getTaxonAttributsAndMedia(cd_nom: number, id_attributs?: Array<number>) {
    let query_string = new HttpParams();
    if (id_attributs) {
      id_attributs.forEach((id) => {
        query_string = query_string.append('id_attribut', id.toString());
      });
    }

    return this._http.get<any>(`${AppConfig.API_TAXHUB}/bibnoms/taxoninfo/${cd_nom}`, {
      params: query_string,
    });
  }

  getTaxaBibList() {
    return this._http.get<any>(`${AppConfig.API_TAXHUB}/biblistes/`).pipe(map((d) => d.data));
  }

  async getTaxonInfoSynchrone(cd_nom: number): Promise<any> {
    const response = await this._http
      .get<Taxon>(`${AppConfig.API_TAXHUB}/taxref/${cd_nom}`)
      .toPromise();
    return response;
  }

  getHigherTaxa(rank: string, search?) {
    let params: HttpParams = new HttpParams();
    params = params.set('rank_limit', rank);
    params = params.set('fields', 'lb_auteur,nom_complet_html');

    let url = `${AppConfig.API_TAXHUB}/taxref/search/lb_nom`;
    if (search) {
      url = `${url}/${search}`;
    }

    return this._http.get<any>(url, { params: params }).pipe(
      map((data) => {
        return data.map((item) => {
          return this.formatSciname(item);
        });
      })
    );
  }

  /**
   * Met en gras les noms scientifiques retenus.
   * @param item Objet correspondant au nom scientifique. Doit contenir
   * les attributs "cd_nom", "cd_ref", "lb_nom", "lb_auteur" et "nom_complet_html".
   */
  formatSciname(item) {
    if (item['nom_complet_html'] === undefined && item['lb_nom'] !== undefined) {
      item.displayName = item['lb_nom'];
      if (item['lb_auteur']) {
        item.displayName += ` ${item['lb_auteur']}`;
      }
      return item;
    }

    item.displayName = item['nom_complet_html'];
    item.displayName = item.displayName.replace(
      item['lb_auteur'],
      `<span class="text-muted">${item['lb_auteur']}</span>`
    );
    if (item['cd_nom'] === item['cd_ref']) {
      if (item.displayName.includes('<i>')) {
        item.displayName = item.displayName.replaceAll('<i>', '<b><i>');
        item.displayName = item.displayName.replaceAll('</i>', '</i></b>');
      } else {
        item.displayName = item.displayName.replace(item['lb_nom'], `<b>${item['lb_nom']}</b>`);
      }
    }
    return item;
  }

  getRegneAndGroup2Inpn() {
    return this._http.get<any>(`${AppConfig.API_TAXHUB}/taxref/regnewithgroupe2`);
  }

  getTaxhubBibAttributes() {
    return this._http.get<any>(`${AppConfig.API_TAXHUB}/bibattributs/`);
  }

  getTaxonomyHabitat() {
    return this._http.get<any>(`${AppConfig.API_TAXHUB}/taxref/bib_habitats`);
  }

  getTypologyHabitat(id_list: number) {
    let params = new HttpParams();

    if (id_list) {
      params = params.set('id_list', id_list.toString());
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/habref/typo`, { params: params }).pipe(
      map((data) => {
        // replace '_' with space because habref is super clean !
        return data.map((d) => {
          d['lb_nom_typo'] = d['lb_nom_typo'].replace(/_/g, ' ');
          return d;
        });
      })
    );
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

  getAltitudes(geojson) {
    return this._http.post<any>(`${AppConfig.API_ENDPOINT}/geo/altitude`, geojson);
  }

  getFormatedGeoIntersection(geojson, idType?) {
    if (idType) {
      geojson['id_type'] = idType;
    }
    return this._http.post(`${AppConfig.API_ENDPOINT}/geo/areas`, geojson).pipe(
      map((res) => {
        const areasIntersected = [];
        Object.keys(res).forEach((key) => {
          const typeName = res[key]['type_name'];
          const areas = res[key]['areas'];
          const formatedAreas = areas.map((area) => area.area_name).join(', ');
          const obj = {
            type_name: typeName,
            areas: formatedAreas,
          };
          areasIntersected.push(obj);
        });
        return areasIntersected;
      })
    );
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

  getAreas(area_type_list: Array<string>, area_name?) {
    let params: HttpParams = new HttpParams();

    area_type_list.forEach((id_type) => {
      params = params.append('type_code', id_type.toString());
    });

    if (area_name) {
      params = params.set('area_name', area_name);
    }

    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/geo/areas`, { params: params });
  }

  getAreasTypes() {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/geo/types`);
  }

  autocompleteRefGeo(params) {
    let queryString: HttpParams = new HttpParams();
    for (let key in params) {
      queryString = queryString.set(key, params[key]);
    }

    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/geo/areas`, {
      params: queryString,
    });
  }

  getValidationHistory(uuid_attached_row) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/gn_commons/history/${uuid_attached_row}`,
      {}
    );
  }

  /**
   *
   * @param params: dict of paramters
   */
  getAcquisitionFrameworks(params = {}) {
    let queryString: HttpParams = new HttpParams();
    for (let key in params) {
      queryString = queryString.set(key, params[key]);
    }

    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/list/acquisition_frameworks`, {
      params: queryString,
    });
  }

  getAcquisitionFrameworksList(selectors = {}, params = {}) {
    let queryString: HttpParams = new HttpParams();
    for (let key in selectors) {
      queryString = queryString.set(key, selectors[key]);
    }

    return this._http.post<any>(`${AppConfig.API_ENDPOINT}/meta/acquisition_frameworks`, params, {
      params: queryString,
    });
  }

  /**
   * @param id_af: id of acquisition_framework
   * @params params : get parameters
   */
  getAcquisitionFramework(id_af, params?: ParamsDict) {
    let queryString: HttpParams = new HttpParams();
    for (let key in params) {
      if (isArray(params[key])) {
        params[key].forEach((el) => {
          queryString = queryString.append(key, el);
        });
      } else {
        queryString = queryString.set(key, params[key]);
      }
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/acquisition_framework/${id_af}`, {
      params: queryString,
    });
  }

  /**
   * @param id_af: id of acquisition_framework
   */
  getAcquisitionFrameworkStats(id_af) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/meta/acquisition_framework/${id_af}/stats`
    );
  }

  /**
   * @param id_af: id of acquisition_framework
   */
  getAcquisitionFrameworkBbox(id_af) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/meta/acquisition_framework/${id_af}/bbox`
    );
  }

  getOrganisms(orderByName = true) {
    let queryString: HttpParams = new HttpParams();
    if (orderByName) {
      queryString = this.addOrderBy(queryString, 'nom_organisme');
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/organisms`, {
      params: queryString,
    });
  }

  getOrganismsDatasets(orderByName = true) {
    let queryString: HttpParams = new HttpParams();
    if (orderByName) {
      queryString = this.addOrderBy(queryString, 'nom_organisme');
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/organisms_dataset_actor`, {
      params: queryString,
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
    // eslint-disable-next-line guard-for-in
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

  // getTaxaDistribution(id_dataset) {
  //   return this._http.get<any>(`${AppConfig.API_ENDPOINT}/synthese/dataset_taxa_distribution/${id_dataset}`);
  // }
  getGeojsonData(id) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/meta/geojson_data/${id}`);
  }

  getRepartitionTaxons(id_dataset) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/synthese/repartition_taxons_dataset/${id_dataset}`
    );
  }

  exportPDF(img, endPoint, prefix) {
    const source = this._http.post(
      endPoint,
      {
        chart: img,
      },
      {
        observe: 'events',
        responseType: 'blob',
        reportProgress: false,
      }
    );

    this.subscribeAndDownload(source, prefix, 'pdf');
  }

  getTaxaDistribution(taxa_rank, params?: ParamsDict) {
    let queryString = new HttpParams();
    queryString = queryString.set('taxa_rank', taxa_rank);
    for (let key in params) {
      queryString = queryString.set(key, params[key]);
    }

    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/synthese/taxa_distribution`, {
      params: queryString,
    });
  }

  getModulesList(exclude: Array<string> = []): Observable<Array<any>> {
    let queryString: HttpParams = new HttpParams();
    exclude.forEach((mod_code) => {
      queryString = queryString.append('exclude', mod_code);
    });
    return this._http.get<Array<any>>(`${AppConfig.API_ENDPOINT}/gn_commons/modules`, {
      params: queryString,
    });
  }

  getModuleByCodeName(module_code): Observable<any> {
    console.log('WARNING: use moduleService.getModule(module_code) instead?');
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/gn_commons/modules/${module_code}`);
  }

  addOrderBy(httpParam: HttpParams, order_column): HttpParams {
    return httpParam.append('orderby', order_column);
  }

  getDataList(api: string, application: string, params = {}) {
    let queryString: HttpParams = new HttpParams();
    for (const key of Object.keys(params)) {
      const param = params[key];
      if (Array.isArray(param)) {
        for (const p of param) {
          queryString = queryString.append(key, p);
        }
      } else {
        queryString = queryString.append(key, param);
      }
    }

    const url =
      application === 'GeoNature'
        ? `${AppConfig.API_ENDPOINT}/${api}`
        : application === 'TaxHub'
        ? `${AppConfig.API_TAXHUB}/${api}`
        : api;

    return this._http.get<any>(url, { params: queryString });
  }

  subscribeAndDownload(
    source: Observable<HttpEvent<Blob>>,
    fileName: string,
    format: string
  ): void {
    const subscription = source.subscribe(
      (event) => {
        if (event.type === HttpEventType.Response) {
          this._blob = event.body;
        }
      },
      (e: HttpErrorResponse) => {},
      // response OK
      () => {
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
    link.download = filename;
    link.click();
    URL.revokeObjectURL(link.href);
  }

  //liste des lieux
  getPlaces() {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/gn_commons/places`);
  }
  //Ajouter lieu
  addPlace(place) {
    return this._http.post<any>(`${AppConfig.API_ENDPOINT}/gn_commons/places`, place);
  }
  // Supprimer lieu
  deletePlace(idPlace) {
    return this._http.delete<any>(`${AppConfig.API_ENDPOINT}/gn_commons/places/${idPlace}`);
  }

  deleteAf(af_id) {
    return this._http.delete<any>(`${AppConfig.API_ENDPOINT}/meta/acquisition_framework/${af_id}`);
  }

  publishAf(af_id) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/meta/acquisition_framework/publish/${af_id}`
    );
  }

  deleteDs(ds_id) {
    return this._http.delete<any>(`${AppConfig.API_ENDPOINT}/meta/dataset/${ds_id}`);
  }

  getadditionalFields(params?: ParamsDict) {
    let queryString: HttpParams = new HttpParams();
    // eslint-disable-next-line guard-for-in
    for (const key in params) {
      queryString = queryString.set(key, params[key].toString());
    }
    return this._http
      .get<any>(`${AppConfig.API_ENDPOINT}/gn_commons/additional_fields`, { params: queryString })
      .pipe(
        map((additionalFields) => {
          return additionalFields.map((data) => {
            return {
              id_field: data.id_field,
              attribut_label: data.field_label,
              attribut_name: data.field_name,
              required: data.required,
              description: data.description,
              quantitative: data.quantitative,
              unity: data.unity,
              code_nomenclature_type: data.code_nomenclature_type,
              type_widget: data.type_widget.widget_name,
              multi_select: null,
              values: data.field_values,
              value: data.default_value,
              id_list: data.id_list,
              objects: data.objects,
              modules: data.modules,
              datasets: data.datasets,
              key_value: data.type_widget.widget_name === 'nomenclature' ? 'label_default' : null,
              ...data.additional_attributes,
            };
          });
        })
      );
  }

  getStatusValues(statusType: String) {
    return this._http.get<any>(`${AppConfig.API_TAXHUB}/bdc_statuts/status_values/${statusType}`);
  }

  getProfile(cdRef) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/gn_profiles/valid_profile/${cdRef}`);
  }

  getPhenology(cdRef, idNomenclatureLifeStage?) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/gn_profiles/cor_taxon_phenology/
      ${cdRef}?id_nomenclature_life_stage=
      ${idNomenclatureLifeStage}`
    );
  }

  /* A partir d'un id synthese, retourne si l'observation match avec les différents
 critère d'un profil
*/
  getProfileConsistancyData(idSynthese) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/gn_profiles/consistancy_data/${idSynthese}`
    );
  }

  controlProfile(data) {
    return this._http.post<any>(`${AppConfig.API_ENDPOINT}/gn_profiles/check_observation`, data);
  }

  getStatusType(statusTypes: String[]) {
    let queryString: HttpParams = new HttpParams();
    if (statusTypes) {
      queryString = queryString.set('codes', statusTypes.join(','));
    }
    return this._http.get<any>(`${AppConfig.API_TAXHUB}/bdc_statuts/status_types`, {
      params: queryString,
    });
  }
}
